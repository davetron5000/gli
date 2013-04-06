require 'test_helper'
require 'pp'

class TC_testSubCommandParsing < Clean::Test::TestCase
  include TestHelper

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
      with_clue(@results) {
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
      with_clue(@results) {
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

private
  def with_clue(message,&block)
    block.call
  rescue Exception
    PP.pp message,dump=""
    puts dump
    raise
  end

  def app_with_subcommands_storing_results(subcommand_option_handling_strategy = :legacy)
    @results = {}
    @app = CLIApp.new
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
end
