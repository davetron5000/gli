require 'gli.rb'
require 'test/unit'
require 'tempfile'
require 'fake_std_out'

include GLI
class TC_testCommand < Test::Unit::TestCase

  def setup
    GLI.reset
    GLI.program_desc 'A super awesome program'
    GLI.desc 'Some Global Option'
    GLI.switch :g
    GLI.switch :blah
    GLI.long_desc 'This is a very long description for a flag'
    GLI.flag [:y,:yes]
    @pre_called = false
    @post_called = false
    @error_called = false
    GLI.pre { |g,c,o,a| @pre_called = true }
    GLI.post { |g,c,o,a| @post_called = true }
    GLI.on_error { |g,c,o,a| @error_called = true }
    @glob = nil
    @verbose = nil
    @glob_verbose = nil
    @configure = nil
    @args = nil
    GLI.desc 'Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?'
    GLI.long_desc 'This is the long description: "Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?"'
    GLI.arg_name 'first_file second_file'
    GLI.command [:basic,:bs] do |c|
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
    GLI.desc "Testing long help wrapping"
    GLI.long_desc <<-EOS
    This will create a scaffold command line project that uses GLI
    for command line processing.  Specifically, this will create
    an executable ready to go, as well as a lib and test directory, all
    inside the directory named for your project
    EOS
    GLI.command [:test_wrap] do |c|
      c.action {}
    end
    GLI.desc "Testing paragraph help wrapping"
    GLI.long_desc <<-EOS
    This will create a scaffold command line project that uses GLI
    for command line processing.  Specifically, this will create
    an executable ready to go, as well as a lib and test directory, all
    inside the directory named for your project.

    However, it should maintain the whitespace between paragraphs even
    when fixing the wrapping.
    EOS
    GLI.command [:test_para] do |c|
      c.action {}
    end

    GLI.desc "Testing paragraph help wrapping - multiple lines between paragraphs"
    GLI.long_desc <<-EOS
    This will create a scaffold command line project that uses GLI
    for command line processing.  Specifically, this will create
    an executable ready to go, as well as a lib and test directory, all
    inside the directory named for your project.



    However, it should maintain the whitespace between paragraphs even
    when fixing the wrapping. Ignoring multiple blank lines.
    EOS
    GLI.command [:test_para_multi] do |c|
      c.action {}
    end

    GLI.desc "Testing line and paragraph wrapping - bounds checks"
    GLI.long_desc <<-EOS
    Many short sentences
    Trailing spaces     
        Leading spaces
    Multi     spaces
    Single line

    77wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vitae

    76wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vita

    Roll over properly with no trailing spaces a a a a a a a a a a a a a a a a a a
    74wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vi

    75wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vit

    75wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vit
    77wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vitae
    76wide lobortis elit arcu fringilla dictum. Pellentesque volutpat felis vita
    EOS
    GLI.command [:test_para_bounds] do |c|
      c.action {}
    end

    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new
    DefaultHelpCommand.output_device=@fake_stdout
    DefaultHelpCommand.skips_pre=true
    DefaultHelpCommand.skips_post=true
    GLI.error_device=@fake_stderr
  end

  def tear_down
    FileUtils.rm_f "cruddo.rdoc"
    DefaultHelpCommand.output_device=$stdout
  end

  def test_names
    command = Command.new([:ls,:list,:'list-them-all'],"List")
    assert_equal "ls, list-them-all, list",command.names
  end

  def test_command_sort
    commands = [Command.new(:foo,"foo")]
    commands << Command.new(:bar,"bar")
    commands << Command.new(:zazz,"zazz")
    commands << Command.new(:zaz,"zaz")

    sorted = commands.sort
    assert_equal :bar,sorted[0].name
    assert_equal :foo,sorted[1].name
    assert_equal :zaz,sorted[2].name
    assert_equal :zazz,sorted[3].name
  end

  def test_basic_command
    args_args = [%w(-g basic -v -c foo bar baz quux), %w(-g basic -v --configure=foo bar baz quux)]
    args_args.each do |args|
      GLI.run(args)
      assert_equal('true',@glob)
      assert_equal('true',@verbose)
      assert_equal('false',@glob_verbose)
      assert_equal('foo',@configure)
      assert_equal(%w(bar baz quux),@args)
      assert(@pre_called,"Pre block should have been called")
      assert(@post_called,"Post block should have been called")
      assert(!@error_called,"Error block should not have been called")
    end
  end

  def test_command_skips_pre
    GLI.skips_pre
    GLI.skips_post

    skips_pre_called = false
    runs_pre_called = false

    GLI.command [:skipspre] do |c| 
      c.action do |g,o,a|
        skips_pre_called = true
      end
    end

    # Making sure skips_pre doesn't leak to other commands
    GLI.command [:runspre] do |c|
      c.action do |g,o,a|
        runs_pre_called = true
      end
    end

    GLI.run(['skipspre'])

    assert(skips_pre_called,"'skipspre' should have been called")
    assert(!@pre_called,"Pre block should not have been called")
    assert(!@post_called,"Post block should not have been called")
    assert(!@error_called,"Error block should not have been called")

    GLI.run(['runspre'])

    assert(runs_pre_called,"'runspre' should have been called")
    assert(@pre_called,"Pre block should not have been called")
    assert(@post_called,"Post block SHOULD have been called")
    assert(!@error_called,"Error block should not have been called")
  end

  def test_command_no_globals
    args = %w(basic -c foo bar baz quux)
    GLI.run(args)
    assert_equal('foo',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_defaults_get_set
    args = %w(basic bar baz quux)
    GLI.run(args)
    assert_equal('false',@glob)
    assert_equal('false',@verbose)
    assert_equal('crud',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_no_arguments
    args = %w(basic -v)
    GLI.run(args)
    assert_equal('true',@verbose)
    assert_equal('crud',@configure)
    assert_equal([],@args)
  end

  def test_unknown_command
    args = %w(blah)
    GLI.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ help/)
    assert_contained(@fake_stderr,/list of commands/)
  end

  def test_unknown_global_option
    args = %w(--quux basic)
    GLI.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ help/)
    assert_contained(@fake_stderr,/list of global options/)
  end

  def test_unknown_argument
    args = %w(basic --quux)
    GLI.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ help basic/)
    assert_contained(@fake_stderr,/list of command options/)
  end

  def test_help
    args = %w(help)
    GLI.run(args)
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
    GLI.config_file(config_file.path)
    GLI.run(%w(help))
    assert_contained(@fake_stdout,/\(default: foo\)/)
  end

  def test_help_with_pre_called
    args = %w(help)
    GLI::DefaultHelpCommand.skips_pre=false
    GLI::DefaultHelpCommand.skips_post=false
    GLI.run(args)
    assert(@pre_called,"Expected pre block to have been called")
    assert(@post_called,"Expected pre block to have been called")
  end

  def test_help_without_any_descs_still_works
    GLI.reset
    GLI.flag :f
    GLI.command :foo do |c|
    end
    exit_status = GLI.run(%w(help foo))
    assert_not_contained(@fake_stderr,/nil/)
    assert_not_contained(@fake_stdout,/nil/)
    assert_equal exit_status,0
  end

  def test_help_one_command
    args = %w(help basic)
    GLI.run(args)
    ['Command Options:','\[command options\]'].each do |opt|
      assert_contained(@fake_stdout,/#{opt}/)
    end
  end

  def test_long_help_wrapping
    ENV['COLUMNS'] = '80'
    ENV['LINES'] = '24'
    args = %w(help test_wrap)
    GLI.run(args)
    @fake_stdout.strings.each do |str|
      str.split("\n").each do |line|
        assert(line.size <= ENV['COLUMNS'].to_i, 
               "Help message should not exceed #{ENV['COLUMNS']} columns, but was #{line.size}")
      end
    end
  end

  def test_paragraph_help_wrapping
    ENV['COLUMNS'] = '80'
    ENV['LINES'] = '24'
    args = %w(help test_para)
    GLI.run(args)
    @fake_stdout.strings.each do |str|
      lines = str.split("\n")
      lines.each do |line|
        assert(line.size <= ENV['COLUMNS'].to_i,
               "Help message should not exceed #{ENV['COLUMNS']} columns, but was #{line.size}")
      end
    end
    total_lines = @fake_stdout.strings.inject(0) { |total, string| total + string.split("\n").size }
    expected_lines = 9
    assert_equal expected_lines, total_lines, "Help message should maintain paragraphs and span #{expected_lines} lines, but spanned #{total_lines} lines"
  end

  def test_paragraph_help_wrapping_multi_line
    ENV['COLUMNS'] = '80'
    ENV['LINES'] = '24'
    args = %w(help test_para_multi)
    GLI.run(args)
    @fake_stdout.strings.each do |str|
      lines = str.split("\n")
      lines.each do |line|
        assert(line.size <= ENV['COLUMNS'].to_i,
               "Help message should not exceed #{ENV['COLUMNS']} columns, but was #{line.size}")
      end
    end
    total_lines = @fake_stdout.strings.inject(0) { |total, string| total + string.split("\n").size }
    expected_lines = 9
    assert_equal expected_lines, total_lines, "Help message should maintain paragraphs, ignoring multiple blank lines, and span #{expected_lines} lines, but spanned #{total_lines} lines"
  end

  def test_paragraph_wrapping_bounds
    ENV['COLUMNS'] = '80'
    ENV['LINES'] = '24'
    args = %w(help test_para_bounds)
    GLI.run(args)
    @fake_stdout.strings.each do |str|
      lines = str.split("\n")
      lines.each do |line|
        assert(line.size <= ENV['COLUMNS'].to_i,
               "Help message should not exceed #{ENV['COLUMNS']} columns, but was #{line.size}")
      end
    end
    total_lines = @fake_stdout.strings.inject(0) { |total, string| total + string.split("\n").size }
    expected_lines = 18
    assert_equal expected_lines, total_lines, "Help message should maintain paragraphs, ignoring varying line lengths, multiple spaces and span #{expected_lines} lines, but spanned #{total_lines} lines"
  end

  def test_version
    GLI.command :foo, :bar do |c|; end
    GLI.command :ls, :list do |c|; end
    GLI.version '1.3.4'
    args = %w(help)
    GLI.run(args)
    assert_not_nil @fake_stdout.strings.find{ |x| x =~ /^Version: 1.3.4/ }
  end

  def test_version_not_specified
    GLI.command :foo, :bar do |c|; end
    GLI.command :ls, :list do |c|; end
    args = %w(help)
    GLI.run(args)
    assert_nil @fake_stdout.strings.find{ |x| x =~ /^Version: 1.3.4/ }
  end

  def test_help_completion
    GLI.command :foo, :bar do |c|; end
    GLI.command :ls, :list do |c|; end
    args = %w(help -c)
    GLI.run(args)
    assert_equal 11,@fake_stdout.strings.size
    assert_equal ['bar','basic','bs','foo','help','list','ls', 'test_para', 'test_para_bounds', 'test_para_multi', 'test_wrap'],@fake_stdout.strings
  end

  def test_help_completion_partial
    GLI.command :foo, :bar do |c|; end
    GLI.command :ls, :list do |c|; end
    args = %w(help -c b)
    GLI.run(args)
    assert_equal 3,@fake_stdout.strings.size
    assert_equal ['bar','basic','bs'],@fake_stdout.strings
  end

  def test_rdoc
    GLI.program_name 'cruddo'
    args = %w(rdoc)
    GLI.run(args)
    assert File.exists?("cruddo.rdoc")
  end

  def test_help_no_command
    GLI.program_name 'cruddo'
    args = %w(help foo)
    GLI.run(args)
    assert_equal('cruddo',GLI.program_name)
  end

  def test_command_create
    GLI.desc 'single symbol'
    GLI.command :single do |c|; end
    command = GLI.commands[:single]
    assert_equal :single, command.name
    assert_equal nil, command.aliases
  
    description = 'implicit array'
    GLI.desc description
    GLI.command :foo, :bar do |c|; end
    command = GLI.commands[:foo]
    assert_equal :foo, command.name
    assert_equal [:bar], command.aliases

    description = 'explicit array'
    GLI.desc description
    GLI.command [:baz, :blah] do |c|; end
    command = GLI.commands[:baz]
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
