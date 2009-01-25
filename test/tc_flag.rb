require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testFlag < Test::Unit::TestCase

  def test_basics_simple
    flag = Flag.new(:filename,'Use filename')
    do_basic_asserts(flag,:filename,nil,'Use filename')
  end

  def test_basics_kinda_complex
    flag = Flag.new([:f],'Use filename')
    do_basic_asserts(flag,:f,nil,'Use filename')
  end

  def test_basics_complex
    flag = Flag.new([:f,:file,:filename],'Use filename')
    do_basic_asserts(flag,:f,[:file,:filename],'Use filename')
  end

  def do_basic_asserts(flag,name,aliases,desc)
    assert_equal(name,flag.name)
    assert_equal(aliases,flag.aliases)
    assert_equal(desc,flag.description)
    assert_equal("#{Flag.as_flag(name)} - #{desc}",flag.usage)
  end
  def test_find_one_flag
    args = %w(foo bar -f -g -h baz)
    flag = Flag.new(:f,"Some Flag")
    args_size = args.length
    present = flag.get_value!(args)
    assert(present)
    assert_equal(args_size - 1,args.size)
  end

  def test_find_one_flag_long
    args = %w(foo bar --file -g -h baz)
    flag = Flag.new([:f,:file,:bar],"Some Flag")
    args_size = args.length
    present = flag.get_value!(args)
    assert(present)
    assert_equal(args_size - 1,args.size)
  end

  def test_find_many_flags
    args = %w(foo bar -f -g --file -h baz -f -file --fileblah --f)
    flag = Flag.new([:f,:file],"Some Flag")
    args_size = args.length
    times = 0
    while flag.get_value!(args)
      times += 1
    end
    assert_equal(3,times)
    assert_equal(args_size - times,args.size)
  end

  def test_find_flag_not_there
    args = %w(foo bar -f -g -h baz)
    flag = Flag.new(:i,"Some Flag")
    args_size = args.length
    present = flag.get_value!(args)
    assert(!present)
    assert_equal(args_size,args.size)
  end
end
