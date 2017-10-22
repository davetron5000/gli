require 'test_helper'

class TC_testHelp < Clean::Test::TestCase
  include TestHelper

  def setup
    @option_index = 0
    @real_columns = ENV['COLUMNS']
    ENV['COLUMNS'] = '1024'
    @output = StringIO.new
    @error = StringIO.new
    @command_names_used = []
    # Reset help command to its default state
    GLI::Commands::Help.skips_pre    = true
    GLI::Commands::Help.skips_post   = true
    GLI::Commands::Help.skips_around = true
  end

  def teardown
    ENV['COLUMNS'] = @real_columns
  end

  class TestApp
    include GLI::App
  end

  test_that "the help command is configured properly when created" do
    Given {
      app = TestApp.new
      app.subcommand_option_handling :normal
      @command = GLI::Commands::Help.new(app,@output,@error)
    }
    Then {
      assert_equal   'help',@command.name.to_s
      assert_nil     @command.aliases
      assert_equal   'command',@command.arguments_description
      assert_not_nil @command.description
      assert_not_nil @command.long_description
      assert         @command.skips_pre
      assert         @command.skips_post
      assert         @command.skips_around
    }
  end

  test_that "the help command can be configured to skip things declaratively" do
    Given {
      app = TestApp.new
      app.subcommand_option_handling :normal
      @command = GLI::Commands::Help.new(app,@output,@error)
      GLI::Commands::Help.skips_pre    = false
      GLI::Commands::Help.skips_post   = false
      GLI::Commands::Help.skips_around = false
    }
    Then {
      assert !@command.skips_pre
      assert !@command.skips_post
      assert !@command.skips_around
    }
  end

  test_that "the help command can be configured to skip things declaratively regardless of when the object was created" do
    Given {
      GLI::Commands::Help.skips_pre    = false
      GLI::Commands::Help.skips_post   = false
      GLI::Commands::Help.skips_around = false
      app = TestApp.new
      app.subcommand_option_handling :normal
      @command = GLI::Commands::Help.new(app,@output,@error)
    }
    Then {
      assert !@command.skips_pre
      assert !@command.skips_post
      assert !@command.skips_around
    }
  end

  test_that "invoking help with no arguments results in listing all commands and global options" do
    Given a_GLI_app
    And {
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[])
    }
    Then {
      assert_top_level_help_output
    }
  end

  test_that "invoking help with a command that doesn't exist shows an error" do
    Given a_GLI_app
    And {
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @unknown_command_name = any_command_name
    }
    When {
      @command.execute({},{},[@unknown_command_name])
    }
    Then {
      assert_error_contained(/error: Unknown command '#{@unknown_command_name}'./)
    }
  end

  test_that "invoking help with a known command shows help for that command" do
    Given a_GLI_app
    And {
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc
      @switch       = s  = any_option
      @switch_desc  = sd = any_desc
      @flag         = f  = any_option
      @flag_desc    = fd = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|

          c.desc sd
          c.switch s

          c.desc fd
          c.flag f

          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[@command_name])
    }
    Then {
      assert_output_contained(@command_name,"Name of the command")
      assert_output_contained(@desc,"Short description")
      assert_output_contained(@long_desc,"Long description")
      assert_output_contained("-" + @switch,"command switch")
      assert_output_contained(@switch_desc,"switch description")
      assert_output_contained("-" + @flag,"command flag")
      assert_output_contained(@flag_desc,"flag description")
    }
  end

  test_that 'invoking help for an app with no global options omits [global options] from the usage string' do
    Given a_GLI_app(:no_options)
    And {
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[])
    }
    Then {
      refute_output_contained(/\[global options\] command \[command options\] \[arguments\.\.\.\]/)
      refute_output_contained('GLOBAL OPTIONS')
      assert_output_contained(/command \[command options\] \[arguments\.\.\.\]/)
    }
  end

  test_that "invoking help with a known command when no global options are present omits [global options] from the usage string" do
    Given a_GLI_app(:no_options)
    And {
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc
      @switch       = s  = any_option
      @switch_desc  = sd = any_desc
      @flag         = f  = any_option
      @flag_desc    = fd = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|

          c.desc sd
          c.switch s

          c.desc fd
          c.flag f

          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[@command_name])
    }
    Then {
      refute_output_contained(/\[global options\]/)
      assert_output_contained(/\[command options\]/)
      assert_output_contained('COMMAND OPTIONS')
    }
  end

  test_that "invoking help with a known command when no global options nor command options are present omits [global options] and [command options] from the usage string" do
    Given a_GLI_app(:no_options)
    And {
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|
          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[@command_name])
    }
    Then {
      refute_output_contained(/\[global options\]/)
      refute_output_contained(/\[command options\]/)
      refute_output_contained('COMMAND OPTIONS')
    }
  end

  test_that "invoking help with a known command that has no command options omits [command options] from the usage string" do
    Given a_GLI_app
    And {
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|
          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
    }
    When {
      @command.execute({},{},[@command_name])
    }
    Then {
      assert_output_contained(/\[global options\]/)
      refute_output_contained(/\[command options\]/)
      refute_output_contained('COMMAND OPTIONS')
    }
  end

  test_that "omitting default_description doesn't blow up" do
    Given {
      app = TestApp.new
      app.instance_eval do
        subcommand_option_handling :normal
        command :top do |top|
          top.command :list do |list|
            list.action do |g,o,a|
            end
          end

          top.command :new do |new|
            new.action do |g,o,a|
            end
          end

          top.default_command :list
        end
      end
      @command = GLI::Commands::Help.new(app,@output,@error)
    }
    When {
      @code = lambda { @command.execute({},{},['top']) }
    }
    Then {
      assert_nothing_raised(&@code)
    }
  end

private

  def a_GLI_app(omit_options=false)
    lambda {
      @program_description = program_description = any_desc
      @flags = flags = [
        [any_desc.strip,any_arg_name,[any_option]],
        [any_desc.strip,any_arg_name,[any_option,any_long_option]],
      ]
      @switches = switches = [
        [any_desc.strip,[any_option]],
        [any_desc.strip,[any_option,any_long_option]],
      ]

      @commands = commands = [
        [any_desc.strip,[any_command_name]],
        [any_desc.strip,[any_command_name,any_command_name]],
      ]

      @app = TestApp.new
      @app.instance_eval do
        program_desc program_description
        subcommand_option_handling :normal

        unless omit_options
          flags.each do |(description,arg,flag_names)|
            desc description
            arg_name arg
            flag flag_names
          end

          switches.each do |(description,switch_names)|
            desc description
            switch switch_names
          end
        end

        commands.each do |(description,command_names)|
          desc description
          command command_names do |c|
            c.action {}
          end
        end
      end
    }
  end

  def assert_top_level_help_output
    assert_output_contained(@program_description)

    @commands.each do |(description,command_names)|
      assert_output_contained(/#{command_names.join(', ')}\s+-\s+#{description}/,"For command #{command_names.join(',')}")
    end
    assert_output_contained(/help\s+-\s+#{@command.description}/)

    @switches.each do |(description,switch_names)|
      expected_switch_names = switch_names.map { |_| _.length == 1 ? "-#{_}" : "--\\[no-\\]#{_}" }.join(', ')
      assert_output_contained(/#{expected_switch_names}\s+-\s+#{description}/,"For switch #{switch_names.join(',')}")
    end

    @flags.each do |(description,arg,flag_names)|
      expected_flag_names = flag_names.map { |_| _.length == 1 ? "-#{_}" : "--#{_}" }.join(', ')
      assert_output_contained(/#{expected_flag_names}[ =]#{arg}\s+-\s+#{description}/,"For flag #{flag_names.join(',')}")
    end

    assert_output_contained('GLOBAL OPTIONS')
    assert_output_contained('COMMANDS')
    assert_output_contained(/\[global options\] command \[command options\] \[arguments\.\.\.\]/)
  end

  def assert_error_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    assert_match string_or_regexp,@error.string,desc
  end

  def assert_output_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    assert_match string_or_regexp,@output.string,desc
  end

  def refute_output_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    assert_no_match string_or_regexp,@output.string,desc
  end

  def any_option
    ('a'..'z').to_a[@option_index].tap { @option_index += 1 }
  end

  def any_long_option
    Faker::Lorem.words(10)[rand(10)]
  end

  def any_arg_name
    any_string :max => 20
  end

  def any_desc
    Faker::Lorem.words(10).join(' ')[0..30].gsub(/\s*$/,'')
  end

  def any_command_name
    command_name = Faker::Lorem.words(10)[rand(10)]
    while @command_names_used.include?(command_name)
      command_name = Faker::Lorem.words(10)[rand(10)]
    end
    @command_names_used << command_name
    command_name
  end
end
