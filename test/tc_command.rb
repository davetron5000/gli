require 'gli.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testCommand < Test::Unit::TestCase

  def setup
    GLI.reset
    GLI.desc 'Some Global Option'
    GLI.switch :g
    @glob = nil
    @verbose = nil
    @glob_verbose = nil
    @configure = nil
    @args = nil
    GLI.desc 'Some Basic Command'
    GLI.command :basic do |c|
      c.desc 'be verbose'
      c.switch :v
      c.desc 'configure something'
      c.default_value 'crud'
      c.flag [:c,:configure]
      c.action = Proc.new do |global_options,options,arguments|
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
  end

  def test_help
    args = %w(help basic)
    GLI.run(args)
  end

  def test_command_create
    description = 'List all files'
    GLI.desc description
    GLI.command [:ls,:list] do |c|
    end
  end

end
