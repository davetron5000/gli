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
end
