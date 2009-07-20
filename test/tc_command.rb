require 'gli.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testCommand < Test::Unit::TestCase

  def setup
    GLI.reset
    GLI.desc 'Some Global Option'
    GLI.switch :g
    GLI.switch :blah
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
    GLI.desc 'Some Basic Command that potentially has a really reall long description and stuff, but you know, who cares?'
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
      assert(@pre_called)
      assert(@post_called)
      assert(!@error_called)
    end
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
    args = %w(blah -v)
    GLI.run(args)
    assert(!@post_called)
    assert(@error_called)
  end

  def test_help
    args = %w(help basic)
    GLI.run(args)
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

end
