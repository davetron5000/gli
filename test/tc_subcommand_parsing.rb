require 'test_helper'
require 'pp'

class TC_testSubCommandParsing < Clean::Test::TestCase
  include TestHelper

  def setup
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new

    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr

    @app = CLIApp.new
    @app.reset
    @app.subcommand_option_handling :legacy
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')

    @results = {}
    @exit_code = 0
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  test_that "commands options may clash with globals and it gets sorted out" do
    Given :app_with_subcommands_storing_results
    When {
      @app.run(%w(-f global command1 -f command -s foo))
    }
    Then {
      assert_equal  'command1',@results[:command_name]
      assert_equal  'global',  @results[:global_options][:f],'global'
      assert       !@results[:global_options][:s]
      assert_equal  'command', @results[:command_options][:f]
      assert        @results[:command_options][:s]
    }
  end

  test_that "in legacy mode, subcommand options all share a namespace" do
    Given :app_with_subcommands_storing_results
    When {
      @app.run(%w(-f global command1 -f command -s subcommand10 -f sub))
    }
    Then {
      with_clue {
        assert_equal  'subcommand10',@results[:command_name]
        assert_equal  'global',      @results[:global_options][:f],'global'
        assert       !@results[:global_options][:s]
        assert_equal  'sub', @results[:command_options][:f]
        assert        @results[:command_options][:s]
        assert_nil    @results[:command_options][GLI::Command::PARENT]
        assert_nil    @results[:command_options][GLI::Command::PARENT]
      }
    }
  end

  test_that "in normal mode, each subcommand has its own namespace" do
    Given :app_with_subcommands_storing_results, :normal
    When {
      @app.run(%w(-f global command1 -f command -s subcommand10 -f sub))
    }
    Then {
      with_clue {
        assert_equal  'subcommand10',@results[:command_name]
        assert_equal  'global',      @results[:global_options][:f],'global'
        assert       !@results[:global_options][:s]
        assert_equal  'sub', @results[:command_options][:f]
        assert       !@results[:command_options][:s]
        assert_equal  'command',@results[:command_options][GLI::Command::PARENT][:f]
        assert        @results[:command_options][GLI::Command::PARENT][:s]
      }
    }
  end

  test_that "in loose mode, argument validation is ignored" do
    Given :app_with_arguments, 1, 1, false, :loose
    When :run_app_with_X_arguments, 0
    Then {
      with_clue {
        assert_equal 0, @results[:number_of_args_give_to_action]
        assert_equal 0, @exit_code
      }
    }
  end

  test_that "in strict mode, subcommand_option_handling must be normal" do
    Given :app_with_arguments, 1, 1, false, :strict, :legacy
    When :run_app_with_X_arguments, 1
    Then {
      with_clue {
        assert_nil      @results[:number_of_args_give_to_action]
        assert_equal 1, @exit_code
        assert          @fake_stderr.contained?(/you must enable normal subcommand_option_handling/)
      }
    }
  end

  ix = -1
  [
    [1 , 1 , false , 0  , :not_enough] ,
    [1 , 1 , false , 1  , :success]    ,
    [1 , 1 , false , 2  , :success]    ,
    [1 , 1 , false , 3  , :too_many]   ,
    [1 , 1 , true  , 0  , :not_enough] ,
    [1 , 1 , true  , 1  , :success]    ,
    [1 , 1 , true  , 2  , :success]    ,
    [1 , 1 , true  , 3  , :success]    ,
    [1 , 1 , true  , 30 , :success]    ,
    [0 , 0 , false , 0  , :success]    ,
    [0 , 0 , false , 1  , :too_many]   ,
    [0 , 1 , false , 1  , :success]    ,
    [0 , 1 , false , 0  , :success]    ,
    [1 , 0 , false , 1  , :success]    ,
    [1 , 0 , false , 0  , :not_enough] ,
    [0 , 0 , true  , 0  , :success]    ,
    [0 , 0 , true  , 10 , :success]

  ].each do |number_required, number_optional, has_multiple, number_generated, status|
    ix = ix + 1
    test_that "in strict mode, with #{number_required} required, #{number_optional} optional, #{ has_multiple ? 'multiple' : 'not multiple' } and #{number_generated} generated, it should be #{status}" do
      Given :app_with_arguments, number_required, number_optional, has_multiple, :strict
      When :run_app_with_X_arguments, number_generated
      Then {
        with_clue {
          if status == :success then
            assert_equal number_generated, @results[:number_of_args_give_to_action]
            assert_equal 0, @exit_code
            assert !@fake_stderr.contained?(/Not enough arguments for command/)
            assert !@fake_stderr.contained?(/Too many arguments for command/)
          elsif status == :not_enough then
            assert_equal nil, @results[:number_of_args_give_to_action]
            assert_equal 64, @exit_code
            assert @fake_stderr.contained?(/Not enough arguments for command/)
          elsif status == :too_many then
            assert_equal nil, @results[:number_of_args_give_to_action]
            assert_equal 64, @exit_code
            assert @fake_stderr.contained?(/Too many arguments for command/)
          else
            assert false
          end
        }
      }
    end
  end
private
  def with_clue(&block)
    block.call
  rescue Exception
    dump = ""
    PP.pp "\nRESULTS---#{@results}", dump unless @results.empty?
    PP.pp "\nSTDERR---\n#{@fake_stderr.to_s}", dump
    PP.pp "\nSTDOUT---\n#{@fake_stdout.to_s}", dump
    @original_stdout.puts dump
    raise
  end

  def app_with_subcommands_storing_results(subcommand_option_handling_strategy = :legacy)
    @app.subcommand_option_handling subcommand_option_handling_strategy
    @app.flag ['f','flag']
    @app.switch ['s','switch']

    2.times do |i|
      @app.command "command#{i}" do |c|
        c.flag ['f','flag']
        c.switch ['s','switch']
        c.action do |global,options,args|
          @results = {
            :command_name => "command#{i}",
            :global_options => global,
            :command_options => options,
            :args => args
          }
        end

        2.times do |j|
          c.command "subcommand#{i}#{j}" do |subcommand|
            subcommand.flag ['f','flag']
            subcommand.flag ['foo']
            subcommand.switch ['s','switch']
            subcommand.action do |global,options,args|
              @results = {
                :command_name => "subcommand#{i}#{j}",
                :global_options => global,
                :command_options => options,
                :args => args
              }
            end
          end
        end
      end
    end
  end

  def app_with_arguments(number_required_arguments, number_optional_arguments, has_argument_multiple, arguments_handling_strategy = :loose, subcommand_option_handling_strategy = :normal)
    @app.arguments arguments_handling_strategy
    @app.subcommand_option_handling subcommand_option_handling_strategy

    number_required_arguments.times { |i| @app.arg("needed#{i}") }
    number_optional_arguments.times { |i| @app.arg("optional#{i}", :optional) }
    @app.arg :multiple, [:multiple, :optional] if has_argument_multiple

    @app.command :cmd do |c|
      c.action do |g,o,a|
        @results = {
          :number_of_args_give_to_action => a.size
        }
      end
    end
  end

  def run_app_with_X_arguments(number_arguments)
    @exit_code = @app.run [].tap{|args| args << "cmd"; number_arguments.times {|i| args << "arg#{i}"}}
  end
end
