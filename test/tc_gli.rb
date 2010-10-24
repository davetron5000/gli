require 'support/compatibility'
require 'gli.rb'
require 'support/initconfig.rb'
require 'test/unit'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def setup
    @config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/new_config.yaml')
  end

  def teardown
    File.delete(@config_file) if File.exist?(@config_file)
  end

  def test_flag_create
    GLI.reset
    do_test_flag_create(GLI)
    do_test_flag_create(Command.new(:f,'Some command'))
  end

  def test_init_from_config
    failure = nil
    GLI.reset
    GLI.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml'))
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

  def test_no_overwrite_config
    config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml')
    config_file_contents = read_file_contents(config_file)
    GLI.reset
    GLI.config_file(config_file)
    GLI.run(['initconfig'])
    config_file_contents_after = read_file_contents(config_file)
    assert_equal(config_file_contents,config_file_contents_after)
  end

  def test_config_file_name
    GLI.reset
    file = GLI.config_file("foo")
    assert_equal(Etc.getpwuid.dir + "/foo",file)
    file = GLI.config_file("/foo")
    assert_equal "/foo",file
    init_command = GLI.commands[:initconfig]
    assert init_command
  end

  def test_initconfig_command
    GLI.reset
    GLI.config_file(@config_file)
    GLI.flag :f
    GLI.switch :s
    GLI.switch :w
    GLI.flag :bigflag
    GLI.flag :biggestflag
    GLI.command :foo do |c|
    end
    GLI.command :bar do |c|
    end
    GLI.command :blah do |c|
    end
    GLI.on_error do |ex|
      raise ex
    end
    GLI.run(['-f','foo','-s','--bigflag=bleorgh','initconfig'])

    written_config = File.open(@config_file) { |f| YAML::load(f) }

    assert_equal 'foo',written_config[:f]
    assert_equal 'bleorgh',written_config[:bigflag]
    assert written_config[:s]
    assert !written_config[:w]
    assert_nil written_config[:biggestflag]
    assert written_config[GLI::InitConfig::COMMANDS_KEY]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:foo]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:bar]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:blah]

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

  def test_two_flags
    GLI.reset
    GLI.on_error do |ex|
      raise ex
    end
    GLI.command [:foo] do |c|
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    GLI.run(['foo', '-i','5','-s','a'])
  end

  def test_two_flags_with_a_default
    GLI.reset
    GLI.on_error do |ex|
      raise ex
    end
    GLI.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    GLI.run(['foo', '-i','5','-s','a'])
  end

  def test_two_flags_using_equals_with_a_default
    GLI.reset
    GLI.on_error do |ex|
      raise ex
    end
    GLI.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    GLI.run(['foo', '-i=5','-s=a'])
  end


  private

  def read_file_contents(filename)
    contents = ""
    File.open(filename) { |file| file.readlines.each { |line| contents += line }}
    contents
  end


end
