require 'gli.rb'
require 'test/unit'

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
    assert(flag.usage != nil)
  end

  def test_find_one_flag
    args = %w(foo bar -f crud)
    flag = Flag.new(:f,'Filename')
    args_size = args.length
    val = flag.get_value!(args)
    assert_equal('crud',val)
    assert_equal(args_size - 2,args.size)
  end

  def test_find_flag_compact
    do_test_find_flag_compact(%w(foo bar --f blah --filename=bleorgh -lfilename crud),'bleorgh',6)
    do_test_find_flag_compact(%w(foo bar --f blah -f bleorgh -lfilename crud),'bleorgh',6)
  end

  def do_test_find_flag_compact(args,expected,expected_size)
    flag = Flag.new([:f,:filename],'Filename')
    val = flag.get_value!(args)
    assert_equal(expected,val)
    assert_equal(expected_size,args.size)
  end

  def test_find_flag_not_present
    args = %w(foo bar --f blah -lfilename bleorgh -lfilename crud)
    flag = Flag.new([:f,:filename],'Filename')
    args_size = args.length
    val = flag.get_value!(args)
    assert_equal(nil,val)
    assert_equal(args_size,args.size)
  end

  def test_bad_command_line
    flag = Flag.new([:f,:filename],'Filename')
    assert_raises(BadCommandLine) { flag.get_value!(%w(foo bar --f blah -f)) }
    assert_raises(BadCommandLine) { flag.get_value!(%w(foo bar --f blah --filename)) }
    assert_raises(BadCommandLine) { flag.get_value!(%w(foo bar --f blah --filename=)) }
    assert_raises(BadCommandLine) { flag.get_value!(%w(foo bar --f blah --filename bleorgh -lfilename crud)) }
  end

end
