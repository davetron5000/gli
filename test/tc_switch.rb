require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testSwitch < Test::Unit::TestCase

  def test_basics_simple
    switch = Switch.new(:f,'Filename','file','~/.blah.rc')
    do_basic_asserts(switch,:f,nil,'Filename')
  end

  def test_basics_kinda_complex
    switch = Switch.new([:f],'Filename','file','~/.blah.rc')
    do_basic_asserts(switch,:f,nil,'Filename')
  end

  def test_basics_complex
    switch = Switch.new([:f,:file,:filename],'Filename','file','~/.blah.rc')
    do_basic_asserts(switch,:f,[:file,:filename],'Filename')
  end

  def do_basic_asserts(switch,name,aliases,desc)
    assert_equal(name,switch.name)
    assert_equal(aliases,switch.aliases)
    assert_equal(desc,switch.description)
  end

  def test_find_one_switch
    args = %w(foo bar -f crud)
    switch = Switch.new(:f,'Filename')
    args_size = args.length
    val = switch.get_value!(args)
    assert_equal('crud',val)
    assert_equal(args_size - 2,args.size)
  end

  def test_find_one_switch_complex
    args = %w(foo bar --f blah -filename bleorgh --filename crud)
    switch = Switch.new([:f,:filename],'Filename')
    args_size = args.length
    val = switch.get_value!(args)
    assert_equal('crud',val)
    assert_equal(args_size - 2,args.size)
  end

  def test_find_switch_not_present
    args = %w(foo bar --f blah -filename bleorgh -filename crud)
    switch = Switch.new([:f,:filename],'Filename')
    args_size = args.length
    val = switch.get_value!(args)
    assert_equal(nil,val)
    assert_equal(args_size,args.size)
  end

end
