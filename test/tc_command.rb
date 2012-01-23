require 'test_helper'
require 'tempfile'

class TC_testCommand < Test::Unit::TestCase
  include TestHelper
  def setup
    @app = CLIApp.new
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
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new
    GLI::DefaultHelpCommand.output_device=@fake_stdout
    GLI::DefaultHelpCommand.skips_pre=true
    GLI::DefaultHelpCommand.skips_post=true
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')
    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr
  end

  def tear_down
    $stdout = @original_stdout
    $stderr = @original_stderr
    FileUtils.rm_f "cruddo.rdoc"
    GLI::DefaultHelpCommand.output_device=$stdout
  end

  def test_names
    command = GLI::Command.new([:ls,:list,:'list-them-all'],"List")
    assert_equal "ls, list, list-them-all",command.names
  end

  def test_command_sort
    commands = [GLI::Command.new(:foo,"foo")]
    commands << GLI::Command.new(:bar,"bar")
    commands << GLI::Command.new(:zazz,"zazz")
    commands << GLI::Command.new(:zaz,"zaz")

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

=begin
  def test_negatable_can_be_avoided
    called = false
    @app.switch :bar, :negatable => false
    @app.command [:foo] do |c|
      c.action do |g,o,a|
        called = true
      end
    end

    assert_equal 0,@app.run(%w(help)),@fake_stdout.to_s + "\n\n\n" + @fake_stderr.to_s
    assert_contained(@fake_stdout,/--bar/)
    assert_not_contained(@fake_stdout,/--[no-]bar/)

    exit_status = @app.run(%w(--no-bar foo))
    assert !called,"Should not have called action block"
    assert_equal -1,exit_status
  end
=end

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
    assert_contained(@fake_stderr,/ help/)
    assert_contained(@fake_stderr,/list of commands/)
  end

  def test_unknown_global_option
    args = %w(--quux basic)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called,"Expected error callback to be called")
    assert_contained(@fake_stderr,/ help/)
    assert_contained(@fake_stderr,/list of global options/)
  end

  def test_unknown_argument
    args = %w(basic --quux)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ help basic/)
    assert_contained(@fake_stderr,/list of command options/)
  end

=begin
  def test_help
    args = %w(help)
    @app.run(args)
    ['\[global options\]','\[command options\]','Global Options:','A super awesome program'].each do |opt|
      assert_contained(@fake_stdout,/#{opt}/)
    end
    assert(!@pre_called,"Expected pre block NOT to have been called")
    assert(!@post_called,"Expected post block NOT to have been called")
  end

  def test_help_with_config_file_shows_config_value
    config_file = Tempfile.new('gli_config')
    config = {
      :blah => true,
      :y => "foo",
    }
    File.open(config_file.path,'w') { |file| YAML.dump(config,file) }
    @app.config_file(config_file.path)
    @app.run(%w(help))
    assert_contained(@fake_stdout,/\(default: foo\)/)
  end

  def test_help_with_pre_called
    args = %w(help)
    GLI::DefaultHelpCommand.skips_pre=false
    GLI::DefaultHelpCommand.skips_post=false
    @app.run(args)
    assert(@pre_called,"Expected pre block to have been called")
    assert(@post_called,"Expected pre block to have been called")
  end

  def test_help_without_any_descs_still_works
    @app.reset
    @app.flag :f
    @app.command :foo do |c|
    end
    exit_status = @app.run(%w(help foo))
    assert_not_contained(@fake_stderr,/nil/)
    assert_not_contained(@fake_stdout,/nil/)
    assert_equal exit_status,0
  end

  def test_help_one_command
    args = %w(help basic)
    @app.run(args)
    ['Command Options:','\[command options\]'].each do |opt|
      assert_contained(@fake_stdout,/#{opt}/)
    end
  end

  def test_long_help_wrapping
    ENV['COLUMNS'] = '80'
    ENV['LINES'] = '24'
    args = %w(help test_wrap)
    @app.run(args)
    @fake_stdout.strings.each do |str|
      str.split("\n").each do |line|
        assert(line.size <= ENV['COLUMNS'].to_i, 
               "Help message should not exceed #{ENV['COLUMNS']} columns, but was #{line.size}")
      end
    end
  end
  def test_version
    @app.command :foo, :bar do |c|; end
    @app.command :ls, :list do |c|; end
    @app.version '1.3.4'
    args = %w(help)
    @app.run(args)
    assert_not_nil @fake_stdout.strings.find{ |x| x =~ /^Version: 1.3.4/ }
  end

  def test_version_not_specified
    @app.command :foo, :bar do |c|; end
    @app.command :ls, :list do |c|; end
    args = %w(help)
    @app.run(args)
    assert_nil @fake_stdout.strings.find{ |x| x =~ /^Version: 1.3.4/ }
  end

  def test_help_completion
    @app.command :foo, :bar do |c|; end
    @app.command :ls, :list do |c|; end
    args = %w(help -c)
    @app.run(args)
    assert_equal 8,@fake_stdout.strings.size
    assert_equal ['bar','basic','bs','foo','help','list','ls', 'test_wrap'],@fake_stdout.strings
  end

  def test_help_completion_partial
    @app.command :foo, :bar do |c|; end
    @app.command :ls, :list do |c|; end
    args = %w(help -c b)
    @app.run(args)
    assert_equal 3,@fake_stdout.strings.size
    assert_equal ['bar','basic','bs'],@fake_stdout.strings
  end

=end
  def test_rdoc
    @app.program_name 'cruddo'
    args = %w(rdoc)
    @app.run(args)
    assert File.exists?("cruddo.rdoc")
  end
=begin
  def test_help_no_command
    @app.program_name 'cruddo'
    args = %w(help foo)
    @app.run(args)
    assert_equal('cruddo',@app.program_name)
  end
=end
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
