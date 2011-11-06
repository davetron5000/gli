require 'gli.rb'
require 'test/unit'

include GLI
class TC_testSwitch < Test::Unit::TestCase

  def test_basics_simple
    switch = Switch.new(:filename,:desc => 'Use filename')
    do_basic_asserts(switch,:filename,nil,'Use filename')
  end

  def test_basics_kinda_complex
    switch = Switch.new([:f],:desc => 'Use filename')
    do_basic_asserts(switch,:f,nil,'Use filename')
  end

  def test_basics_complex
    switch = Switch.new([:f,:file,:filename],:desc => 'Use filename')
    do_basic_asserts(switch,:f,[:file,:filename],'Use filename')
  end

  def test_includes_negatable
    assert_equal '-a',Switch.name_as_string('a')
    assert_equal '--[no-]foo',Switch.name_as_string('foo')
  end

  def do_basic_asserts(switch,name,aliases,desc)
    assert_equal(name,switch.name)
    assert_equal(aliases,switch.aliases)
    assert_equal(desc,switch.description)
    assert(switch.usage != nil)
  end
end
