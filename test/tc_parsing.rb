require 'gli.rb'
require 'test/unit'

include GLI
class TC_testParsing < Test::Unit::TestCase

  def test_parse_command_line_simple
    GLI.reset
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(-v doit)
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(global_options[:v])
    assert_equal(:doit,command.name)
  end

  def test_repeated_arguments
    GLI.reset
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(doit foo foo bar)
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert_equal 3,arguments.size
    assert_equal "foo",arguments[0]
    assert_equal "foo",arguments[1]
    assert_equal "bar",arguments[2]
  end

  def test_parse_command_line_simplish
    GLI.reset
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(doit)
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert(!global_options[:v])
    assert_equal(:doit,command.name)
  end

  def test_parse_command_line
    GLI.reset
    GLI.switch :v
    GLI.flag :f
    GLI.command :doit do |c|
      c.flag :file
      c.flag :v
    end
    argv = %w(-v -f blah doit -v 4 --file=foo bar)
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
    assert_raises(UnknownGlobalArgument) do
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
    assert_raises(UnknownCommandArgument) do
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
    assert_equal(0,arguments.size)
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
    assert_equal(0,arguments.size)
  end

  def test_switch_and_flag_order
    GLI.reset
    GLI.command :doit do |c|
      c.desc "list stuff"
      c.flag [:l,'stuff']
    end

    argv = %w(doit -l 10 list)
    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert_equal '10', command_options[:l]
    assert arguments.include?('list')
  end

  def test_switch_and_flag_order_with_global
    GLI.reset
    argv = %w(-v -f doit list -l 10)

    GLI.switch :v
    GLI.switch :f
    GLI.command :doit do |c|
      c.desc "list stuff"
      c.flag [:l,'stuff']
    end

    global_options,command,command_options,arguments = GLI.parse_options(argv)
    assert_equal '10', command_options[:l]
    assert arguments.include?('list')
  end

  def test_case_that_busted
    GLI.reset
    GLI.desc 'Some Global Option'
    GLI.switch :g
    glob = nil
    verbose = nil
    glob_verbose = nil
    configure = nil
    args = nil
    GLI.desc 'Some Basic Command'
    GLI.command :basic do |c|
      c.desc 'be verbose'
      c.switch :v
      c.desc 'configure something'
      c.flag [:c,:configure]
      c.action do |global_options,options,arguments|
        glob = global_options[:g] ? 'true' : 'false'
        verbose = options[:v] ? 'true' : 'false'
        glob_verbose = global_options[:v] ? 'true' : 'false'
        configure = options[:c]
        args = arguments
      end
    end
    args = %w(-g basic -v -c foo bar baz quux)
    global_options,command,command_options,arguments = GLI.parse_options(args)
    assert(global_options[:g])
    assert_equal(:basic,command.name)
    assert(command_options[:v])
    assert_equal('foo',command_options[:c])
    assert_equal(%w(bar baz quux),arguments)
  end

  def test_possible_issue_with_numbers
    GLI.reset
    GLI.desc 'Create a day''s worth of data for a particular service point'
    GLI.arg_name 'service point ids'
    GLI.command :data do |c|

      c.desc 'Type of data'
      c.arg_name 'either bill, day, or halfhour'
      c.flag [:t,:type]

      c.desc 'Date for the reads (start date for billing)'
      c.arg_name 'date (in yyyy-mm-dd format)'
      c.default_value '2010-04-01'
      c.flag [:d,:date]

      c.desc 'Number of reads, for billing'
      c.arg_name 'number'
      c.default_value '1'
      c.flag :n

      c.desc 'Make like gas data'
      c.switch :g

      c.action do |global_options,options,args|
        raise "at least one service point id required" if args.nil? || args.empty?
        Generate::Data.new(options[:t],options[:d],options[:n].to_i,options[:g],args).go
      end
    end
    args = %w(data -t bill -n 10 1234)
    global_options,command,command_options,arguments = GLI.parse_options(args)
    assert(global_options.empty?)
    assert_equal(:data,command.name)
    assert_equal('bill',command_options[:t])
    assert_equal('10',command_options[:n])
    assert_equal(['1234'],arguments)

  end

  def teardown
    GLI.reset
  end
end
