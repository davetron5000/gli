require 'gli.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def test_flag_create
    do_test_flag_create(GLI)
    do_test_flag_create(Command.new(:f,'Some command'))
  end

  def do_test_flag_create(object)
    description = 'this is a description'
    object.desc description
    object.arg_name 'filename'
    object.default_value '~/.blah.rc'
    object.flag :f
    assert (object.flags[:f] )
    assert_equal(description,object.flags[:f].description)
    assert(nil != object.flags[:f].usage)
    assert(object.usage != nil) if object.respond_to? :usage;
  end

  def test_switch_create
    do_test_switch_create(GLI)
    do_test_switch_create(Command.new(:f,'Some command'))
  end

  def do_test_switch_create(object)
    description = 'this is a description'
    object.desc description
    object.switch :f
    assert (object.switches[:f] )
    assert_equal(description,object.switches[:f].description)
    assert(object.usage != nil) if object.respond_to? :usage;
  end

  def test_switch_create_twice
    do_test_switch_create_twice(GLI)
    do_test_switch_create_twice(Command.new(:f,'Some command'))
  end

  def do_test_switch_create_twice(object)
    description = 'this is a description'
    object.desc description
    object.switch :f
    assert (object.switches[:f] )
    assert_equal(description,object.switches[:f].description)
    object.switch :g
    assert (object.switches[:g])
    assert_equal(nil,object.switches[:g].description)
    assert(object.usage != nil) if object.respond_to? :usage;
  end

end
