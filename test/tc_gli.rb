require 'gli.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def test_flag_create
    GLI.reset
    do_test_flag_create(GLI)
    do_test_flag_create(Command.new(:f,'Some command'))
  end

  def test_init_from_config
    failure = nil
    GLI.reset
    GLI.config_file(File.expand_path(File.dirname(__FILE__) + '/config.yaml'))
    GLI.flag :f
    GLI.switch :s
    GLI.flag :g
    GLI.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          assert_equal "foo",g[:f]
          assert_equal "bar",o[:g]
          assert_nil g[:g]
          assert_nil o[:f]
          assert_nil g[:s]
          assert o[:s]
        rescue Exception => ex
          failure = ex
        end
      end
    end
    GLI.run(['command'])
    raise failure if !failure.nil?
  end

  def test_config_file_name
    GLI.reset
    file = GLI.config_file("foo")
    assert_equal(Etc.getpwuid.dir + "/foo",file)
    file = GLI.config_file("/foo")
    assert_equal "/foo",file
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
    GLI.reset
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
    GLI.reset
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
