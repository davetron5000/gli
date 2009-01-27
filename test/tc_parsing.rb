require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testParsing < Test::Unit::TestCase

  def test_parse_command_line
    GLI.reset
    argv = %w(-v -f blah doit -v 4 --file=foo bar)
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(global_options[:v])
    assert_equal('blah',global_options[:f])
    assert_equal(:doit,command.name)
    assert_equal('4',command_options[:v])
    assert_equal('foo',command_options[:file])
    assert_equal(1,arguments.size)
    assert_equal('bar',arguments[0])
  end

  def test_parse_command_line_errors
    GLI.reset
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(-x doit)
    assert_raises(UnknownArgumentException) do 
      global_options,command,command_options,arguments = GLI.parse_options(argv)
    end
  end

  def test_parse_command_line_errors_2
    GLI.reset
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(doit -x)
    assert_raises(UnknownArgumentException) do 
      global_options,command,command_options,arguments = GLI.parse_options(argv)
    end
  end

  def test_parse_command_line_simple
    GLI.reset
    argv = %w(doit)
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(!global_options[:v])
    assert(!global_options[:f])
    assert_equal(:doit,command.name)
    assert(!command_options[:v])
    assert(!command_options[:file])
    assert(0,arguments.size)
  end

  def test_parse_command_line_with_stop_processing
    GLI.reset
    argv = %w(-v -f doit -f -v -x -- -blah crud foo --x=blah)
    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.flag :file
      c.switch :v
      c.switch :f
      c.switch :x
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(global_options[:v])
    assert(global_options[:f])
    assert_equal(:doit,command.name)
    assert(command_options[:f])
    assert(command_options[:v])
    assert(command_options[:x])
    assert_equal(['-blah','crud','foo','--x=blah'],arguments)
  end

  def test_parse_command_line_with_stop_processing
    GLI.reset
    argv = %w(-- -v -f doit -f -v -x -- -blah crud foo --x=blah)
    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.flag :file
      c.switch :v
      c.switch :f
      c.switch :x
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert_equal(11,arguments.size)
  end

  def test_parse_command_line_with_stop_processing
    GLI.reset
    argv = %w(-v -- -v -f doit -f -v -x -- -blah crud foo --x=blah)
    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.flag :file
      c.switch :v
      c.switch :f
      c.switch :x
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert_equal(11,arguments.size)
  end

  def test_parse_command_line_with_stop_processing2
    GLI.reset
    argv = %w(-v -f doit -f -v -x --)
    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.flag :file
      c.switch :v
      c.switch :f
      c.switch :x
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(global_options[:v])
    assert(global_options[:f])
    assert_equal(:doit,command.name)
    assert(command_options[:f])
    assert(command_options[:v])
    assert(command_options[:x])
    assert_equal([],arguments)
  end

  def test_parse_command_line_all_switches
    GLI.reset
    argv = %w(-v -f doit -f -v -x)
    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.flag :file
      c.switch :v
      c.switch :f
      c.switch :x
    end
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(global_options[:v])
    assert(global_options[:f])
    assert_equal(:doit,command.name)
    assert(command_options[:f])
    assert(command_options[:v])
    assert(command_options[:x])
    assert(0,arguments.size)
  end

  def teardown
    GLI.reset
  end
end
