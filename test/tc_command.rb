require 'test_helper'
require 'tempfile'

class TC_testCommand < Clean::Test::TestCase
  include TestHelper
  def setup
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new
    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr
    @app = CLIApp.new
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')
    @app.reset
    @app.program_desc 'A super awesome program'
    @app.desc 'Some Global Option'
    @app.switch :g
    @app.switch :blah
    @app.long_desc 'This is a very long description for a flag'
    @app.flag [:y,:yes]
    @pre_called = false
    @post_called = false
    @error_called = false
    @app.pre { |g,c,o,a| @pre_called = true }
    @app.post { |g,c,o,a| @post_called = true }
    @app.on_error { |g,c,o,a| @error_called = true }
    @glob = nil
    @verbose = nil
    @glob_verbose = nil
    @configure = nil
    @args = nil
    @app.desc 'Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?'
    @app.long_desc 'This is the long description: "Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?"'
    @app.arg_name 'first_file second_file'
    @app.command [:basic,:bs] do |c|
      c.desc 'be verbose'
      c.switch :v
      c.desc 'configure something or other, in some way that requires a lot of verbose text and whatnot'
      c.default_value 'crud'
      c.flag [:c,:configure]
      c.action do |global_options,options,arguments|
        @glob = global_options[:g] ? 'true' : 'false'
        @verbose = options[:v] ? 'true' : 'false'
        @glob_verbose = global_options[:v] ? 'true' : 'false'
        @configure = options[:c]
        @args = arguments
      end
    end
    @app.desc "Testing long help wrapping"
    @app.long_desc <<-EOS
    This will create a scaffold command line project that uses @app
    for command line processing.  Specifically, this will create
    an executable ready to go, as well as a lib and test directory, all
    inside the directory named for your project
    EOS
    @app.command [:test_wrap] do |c|
      c.action {}
    end
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
    FileUtils.rm_f "cruddo.rdoc"
  end

  def test_names
    command = GLI::Command.new(:names => [:ls,:list,:'list-them-all'],:description => "List")
    assert_equal "ls, list, list-them-all",command.names
  end

  def test_command_sort
    commands = [GLI::Command.new(:names => :foo)]
    commands << GLI::Command.new(:names => :bar)
    commands << GLI::Command.new(:names => :zazz)
    commands << GLI::Command.new(:names => :zaz)

    sorted = commands.sort
    assert_equal :bar,sorted[0].name
    assert_equal :foo,sorted[1].name
    assert_equal :zaz,sorted[2].name
    assert_equal :zazz,sorted[3].name
  end

  def test_basic_command
    args_args = [%w(-g basic -v -c foo bar baz quux), %w(-g basic -v --configure=foo bar baz quux)]
    args_args.each do |args|
      args_orig = args.clone
      @app.run(args)
      assert_equal('true',@glob,"For args #{args_orig}")
      assert_equal('true',@verbose,"For args #{args_orig}")
      assert_equal('false',@glob_verbose,"For args #{args_orig}")
      assert_equal('foo',@configure,"For args #{args_orig}")
      assert_equal(%w(bar baz quux),@args,"For args #{args_orig}")
      assert(@pre_called,"Pre block should have been called for args #{args_orig}")
      assert(@post_called,"Post block should have been called for args #{args_orig}")
      assert(!@error_called,"Error block should not have been called for args #{args_orig}")
    end
  end

  def test_around_filter
    @around_block_called = false
    @app.around do |global_options, command, options, arguments, code|
      @around_block_called = true
      code.call
    end
    @app.run(['bs'])
    assert(@around_block_called, "Wrapper block should have been called")
  end

  def test_around_filter_can_be_skipped
    # Given
    @around_block_called = false
    @action_called = false
    @app.skips_around
    @app.command :skips_around_filter do |c|
      c.action do |g,o,a|
        @action_called = true
      end
    end

    @app.command :uses_around_filter do |c|
      c.action do |g,o,a|
        @action_called = true
      end
    end

    @app.around do |global_options, command, options, arguments, code|
      @around_block_called = true
      code.call
    end

    # When
    exit_status = @app.run(['skips_around_filter'])

    # Then
    assert_equal 0,exit_status
    assert(!@around_block_called, "Wrapper block should have been skipped")
    assert(@action_called,"Action should have been called")

    # When
    @around_block_called = false
    @action_called = false
    exit_status = @app.run(['uses_around_filter'])

    # Then
    assert_equal 0, exit_status
    assert(@around_block_called, "Wrapper block should have been called")
    assert(@action_called,"Action should have been called")
  end

  def test_around_filter_can_be_nested
    @calls = []

    @app.around do |global_options, command, options, arguments, code|
      @calls << "first_pre"
      code.call
      @calls << "first_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "second_pre"
      code.call
      @calls << "second_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "third_pre"
      code.call
      @calls << "third_post"
    end

    @app.command :with_multiple_around_filters do |c|
      c.action do |g,o,a|
        @calls << "action!"
      end
    end

    @app.run(['with_multiple_around_filters'])

    assert_equal ["first_pre", "second_pre", "third_pre", "action!", "third_post", "second_post", "first_post"], @calls
  end

  def test_skipping_nested_around_filters
    @calls = []

    @app.around do |global_options, command, options, arguments, code|
      begin
        @calls << "first_pre"
        code.call
      ensure
        @calls << "first_post"
      end
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "second_pre"
      code.call
      @calls << "second_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "third_pre"
      code.call
      exit_now!
      @calls << "third_post"
    end

    @app.command :with_multiple_around_filters do |c|
      c.action do |g,o,a|
        @calls << "action!"
      end
    end

    @app.run(['with_multiple_around_filters'])

    assert_equal ["first_pre", "second_pre", "third_pre", "action!", "first_post"], @calls
  end

  def test_around_filter_handles_exit_now
    @around_block_called = false
    @error_message = "OH NOES"
    @app.around do |global_options, command, options, arguments, code|
      @app.exit_now! @error_message
      code.call
    end
    exit_code = @app.run(['bs'])
    assert exit_code != 0
    assert_contained(@fake_stderr,/#{@error_message}/)
    assert_not_contained(@fake_stdout,/SYNOPSIS/)
  end

  def test_around_filter_handles_help_now
    @around_block_called = false
    @error_message = "OH NOES"
    @app.around do |global_options, command, options, arguments, code|
      @app.help_now! @error_message
      code.call
    end
    exit_code = @app.run(['bs'])
    assert exit_code != 0
    assert_contained(@fake_stderr,/#{@error_message}/)
    assert_contained(@fake_stdout,/SYNOPSIS/)
  end

  def test_command_skips_pre
    @app.skips_pre
    @app.skips_post

    skips_pre_called = false
    runs_pre_called = false

    @app.command [:skipspre] do |c| 
      c.action do |g,o,a|
        skips_pre_called = true
      end
    end

    # Making sure skips_pre doesn't leak to other commands
    @app.command [:runspre] do |c|
      c.action do |g,o,a|
        runs_pre_called = true
      end
    end

    @app.run(['skipspre'])

    assert(skips_pre_called,"'skipspre' should have been called")
    assert(!@pre_called,"Pre block should not have been called")
    assert(!@post_called,"Post block should not have been called")
    assert(!@error_called,"Error block should not have been called")

    @app.run(['runspre'])

    assert(runs_pre_called,"'runspre' should have been called")
    assert(@pre_called,"Pre block should not have been called")
    assert(@post_called,"Post block SHOULD have been called")
    assert(!@error_called,"Error block should not have been called")
  end

  def test_command_no_globals
    args = %w(basic -c foo bar baz quux)
    @app.run(args)
    assert_equal('foo',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_defaults_get_set
    args = %w(basic bar baz quux)
    @app.run(args)
    assert_equal('false',@glob)
    assert_equal('false',@verbose)
    assert_equal('crud',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_negatable_gets_created
    @app.command [:foo] do |c|
      c.action do |g,o,a|
        assert !g[:blah]
      end
    end
    exit_status = @app.run(%w(--no-blah foo))
    assert_equal 0,exit_status
  end

  def test_arguments_are_not_frozen
    @args = []


    @app.command [:foo] do |c|
      c.action do |g,o,a|
        @args = a
      end
    end
    exit_status = @app.run(%w(foo a b c d e).map { |arg| arg.freeze })
    assert_equal 0,exit_status
    assert_equal 5,@args.length,"Action block was not called"

    @args.each_with_index do |arg,index|
      assert !arg.frozen?,"Expected argument at index #{index} to not be frozen"
    end
  end

  def test_no_arguments
    args = %w(basic -v)
    @app.run(args)
    assert_equal('true',@verbose)
    assert_equal('crud',@configure)
    assert_equal([],@args)
  end

  def test_unknown_command
    args = %w(blah)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/Unknown command 'blah'/)
  end

  def test_unknown_global_option
    args = %w(--quux basic)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called,"Expected error callback to be called")
    assert_contained(@fake_stderr,/Unknown option --quux/)
  end

  def test_unknown_argument
    args = %w(basic --quux)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ Unknown option --quux/)
  end

  def test_forgot_action_block
    @app.reset
    @app.command :foo do
    end

    ENV['GLI_DEBUG'] = 'true'
    assert_raises RuntimeError do
      @app.run(['foo'])
    end
    assert_match /Command 'foo' has no action block/,@fake_stderr.to_s
  end

  def test_command_create
    @app.desc 'single symbol'
    @app.command :single do |c|; end
    command = @app.commands[:single]
    assert_equal :single, command.name
    assert_equal nil, command.aliases
  
    description = 'implicit array'
    @app.desc description
    @app.command :foo, :bar do |c|; end
    command = @app.commands[:foo]
    assert_equal :foo, command.name
    assert_equal [:bar], command.aliases

    description = 'explicit array'
    @app.desc description
    @app.command [:baz, :blah] do |c|; end
    command = @app.commands[:baz]
    assert_equal :baz, command.name
    assert_equal [:blah], command.aliases
  end

  private

  def assert_contained(output,regexp)
    assert_not_nil output.contained?(regexp),
      "Expected output to contain #{regexp.inspect}, output was:\n#{output}"
  end

  def assert_not_contained(output,regexp)
    assert_nil output.contained?(regexp),
      "Didn't expected output to contain #{regexp.inspect}, output was:\n#{output}"
  end

end
