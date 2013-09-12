require 'test_helper'

class TC_testSubCommand < Clean::Test::TestCase
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
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  ['add','new'].each do |name|
    test_that "We run the 'add' subcommand using '#{name}'" do
      Given we_have_a_command_with_two_subcommands
      When  run_app('remote',name,'-f','foo','bar')
      Then  assert_command_ran_with(:add, :command_options => {:f => true}, :args => %w(foo bar))
    end
  end

  test_that "with subcommands, but not using one on the command-line, we run the base action" do
    Given we_have_a_command_with_two_subcommands
    When  run_app('remote','foo','bar')
    Then  assert_command_ran_with(:base, :command_options => {:f => false}, :args => %w(foo bar))
  end

  test_that "switches and flags defined on a subcommand are available" do
    Given we_have_a_command_with_two_subcommands(:switches => [:addswitch], :flags => [:addflag])
    When  run_app('remote','add','--addswitch','--addflag','foo','bar')
    Then  assert_command_ran_with(:add,:command_options => { :addswitch => true, :addflag => 'foo', :f => false },
                                       :args => ['bar'])
  end

  test_that "--help works for subcommands in :normal handling mode" do
    Given { @app.subcommand_option_handling :normal }
    And we_have_a_command_with_two_subcommands
    When { @app.run(["remote", "add", "--help"]) rescue nil }
    Then { assert_no_match /^error/, @fake_stderr.to_s, "should not output an error message" }
  end

  test_that "--help works for subcommands in :legacy handling mode" do
    Given { @app.subcommand_option_handling :legacy }
    And we_have_a_command_with_two_subcommands
    When { @app.run(["remote", "add", "--help"]) rescue nil }
    Then { assert_no_match /^error/, @fake_stderr.to_s, "should not output an error message" }
  end

  test_that "we can reopen commands to add new subcommands" do
    Given {
      @app.command :remote do |p|
        p.command :add do |c|
          c.action do |global_options,command_options,args|
            @ran_command = :add
          end
        end
      end
      @app.command :remote do |p|
        p.command :new do |c|
          c.action do |global_options,command_options,args|
            @ran_command = :new
          end
        end
      end
    }
    When run_app('remote','new')
    Then { assert_equal(@ran_command, :new) }
    When run_app('remote', 'add')
    Then { assert_equal(@ran_command, :add) }
  end

  test_that "reopening commands doesn't re-add them to the output" do
    Given {
      @app.command :remote do |p|
        p.command(:add) { }
      end
      @app.command :remote do |p|
        p.command(:new) { }
      end
    }
    command_names = @app.instance_variable_get("@commands_declaration_order").collect { |c| c.name }
    assert_equal 1, command_names.grep(:remote).size
  end


  test_that "we can reopen commands doesn't cause conflicts" do
    Given {
      @app.command :remote do |p|
        p.command :add do |c|
          c.action do |global_options,command_options,args|
            @ran_command = :remote_add
          end
        end
      end
      @app.command :local do |p|
        p.command :add do |c|
          c.action do |global_options,command_options,args|
            @ran_command = :local_add
          end
        end
      end
    }
    When run_app('remote','add')
    Then { assert_equal(@ran_command, :remote_add) }
    When run_app('local', 'add')
    Then { assert_equal(@ran_command, :local_add) }
  end


  test_that "we can nest subcommands very deep" do
    Given {
      @run_results = { :add => nil, :rename => nil, :base => nil }
      @app.command :remote do |c|

        c.switch :f
        c.command :add do |add|
          add.command :some do |some|
            some.command :cmd do |cmd|
              cmd.switch :s
              cmd.action do |global_options,command_options,args|
                @run_results[:cmd] = [global_options,command_options,args]
              end
            end
          end
        end
      end
      ENV['GLI_DEBUG'] = 'true'
    }
    When run_app('remote','add','some','cmd','-s','blah')
    Then assert_command_ran_with(:cmd, :command_options => {:s => true, :f => false},:args => ['blah'])
  end

  test_that "when any command in the chain has no action, but there's still arguments, indicate we have an unknown command" do
    Given a_very_deeply_nested_command_structure
    Then {
      assert_raises GLI::UnknownCommand do
        When run_app('remote','add','some','foo')
      end
      assert_match /Unknown command 'foo'/,@fake_stderr.to_s
    }
  end

  test_that "when a command in the chain has no action, but there's NO additional arguments, indicate we need a subcommand" do
    Given a_very_deeply_nested_command_structure
    Then {
      assert_raises GLI::BadCommandLine do
        When run_app('remote','add','some')
      end
      assert_match /Command 'some' requires a subcommand/,@fake_stderr.to_s
    }
  end

  private

  def run_app(*args)
    lambda { @exit_code = @app.run(args) }
  end

  def a_very_deeply_nested_command_structure
    lambda {
      @run_results = { :add => nil, :rename => nil, :base => nil }
      @app.command :remote do |c|

        c.switch :f
        c.command :add do |add|
          add.command :some do |some|
            some.command :cmd do |cmd|
              cmd.switch :s
              cmd.action do |global_options,command_options,args|
                @run_results[:cmd] = [global_options,command_options,args]
              end
            end
          end
        end
      end
      ENV['GLI_DEBUG'] = 'true'
    }
  end

  # expected_command - name of command exepcted to have been run
  # options:
  #   - global_options => hash of expected options
  #   - command_options => hash of expected command options
  #   - args => array of expected args
  def assert_command_ran_with(expected_command,options)
    lambda {
      global_options = options[:global_options] || { :help => false }
      @run_results.each do |command,results|
        if command == expected_command
          assert_equal(indifferent_hash(global_options),results[0])
          assert_equal(indifferent_hash(options[:command_options]),results[1])
          assert_equal(options[:args],results[2])
        else
          assert_nil results
        end
      end
    }
  end

  def indifferent_hash(possibly_nil_hash)
    return {} if possibly_nil_hash.nil?
    possibly_nil_hash.keys.each do |key|
      if key.kind_of? Symbol
        possibly_nil_hash[key.to_s] = possibly_nil_hash[key] unless possibly_nil_hash.has_key?(key.to_s)
      elsif key.kind_of? String
        possibly_nil_hash[key.to_sym] = possibly_nil_hash[key] unless possibly_nil_hash.has_key?(key.to_sym)
      end
    end
    possibly_nil_hash
  end

  # options - 
  #     :flags => flags to add to :add
  #     :switiches => switiches to add to :add
  def we_have_a_command_with_two_subcommands(options = {})
    lambda {
      @run_results = { :add => nil, :rename => nil, :base => nil }
      @app.command :remote do |c|

        c.switch :f

        c.desc "add a remote"
        c.command [:add,:new] do |add|

          Array(options[:flags]).each { |_| add.flag _ }
          Array(options[:switches]).each { |_| add.switch _ }
          add.action do |global_options,command_options,args|
            @run_results[:add] = [global_options,command_options,args]
          end
        end

        c.desc "rename a remote"
        c.command :rename do |rename|
          rename.action do |global_options,command_options,args|
            @run_results[:rename] = [global_options,command_options,args]
          end
        end

        c.action do |global_options,command_options,args|
          @run_results[:base] = [global_options,command_options,args]
        end
      end
      ENV['GLI_DEBUG'] = 'true'
    }
  end
end
