require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testFlag < Test::Unit::TestCase

  def test_basics_simple
    flag = Flag.new(:f,'Filename','file','~/.blah.rc')
    do_basic_asserts(flag,:f,nil,'Filename','file','~/.blah.rc')
  end

  def test_basics_kinda_complex
    flag = Flag.new([:f],'Filename','file','~/.blah.rc')
    do_basic_asserts(flag,:f,nil,'Filename','file','~/.blah.rc')
  end

  def test_basics_complex
    flag = Flag.new([:f,:file,:filename],'Filename','file','~/.blah.rc')
    do_basic_asserts(flag,:f,[:file,:filename],'Filename','file','~/.blah.rc')
  end

  def do_basic_asserts(flag,name,aliases,desc,arg_name,default)
    assert_equal(name,flag.name)
    assert_equal(aliases,flag.aliases)
    assert_equal(desc,flag.description)
    assert_equal("#{Switch.as_switch(name)} #{arg_name} - #{desc} (default #{default})",flag.usage)
  end

  def test_find_one_flag
    args = %w(foo bar -f crud)
    flag = Flag.new(:f,'Filename')
    args_size = args.length
    val = flag.get_value!(args)
    assert_equal('crud',val)
    assert_equal(args_size - 2,args.size)
  end

  def test_find_one_flag_complex
    args = %w(foo bar --f blah -filename bleorgh --filename crud)
    flag = Flag.new([:f,:filename],'Filename')
    args_size = args.length
    val = flag.get_value!(args)
    assert_equal('crud',val)
    assert_equal(args_size - 2,args.size)
  end

  def test_find_flag_not_present
    args = %w(foo bar --f blah -filename bleorgh -filename crud)
    flag = Flag.new([:f,:filename],'Filename')
    args_size = args.length
    val = flag.get_value!(args)
    assert_equal(nil,val)
    assert_equal(args_size,args.size)
  end

end
