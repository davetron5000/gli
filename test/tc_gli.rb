# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
unless File.respond_to? :realpath
  class File
    def self.realpath path
      return realpath(File.readlink(path)) if symlink?(path)
      path
    end
  end
end

require 'gli.rb'
require 'support/initconfig.rb'
require 'test/unit'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def setup
    @config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/new_config.yaml')
    @gli_debug = ENV['GLI_DEBUG']
  end

  def teardown
    File.delete(@config_file) if File.exist?(@config_file)
    ENV['GLI_DEBUG'] = @gli_debug
  end

  def test_flag_create
    GLI.reset
    do_test_flag_create(GLI)
    do_test_flag_create(Command.new(:f,'Some command'))
  end

  def test_create_commands_using_strings
    GLI.reset
    GLI.flag ['f','flag']
    GLI.switch ['s','some-switch']
    GLI.command 'command','command-with-dash' do |c|
    end
    assert GLI.commands.include? :command
    assert GLI.flags.include? :f
    assert GLI.switches.include? :s
    assert GLI.commands[:command].aliases.include? :'command-with-dash'
    assert GLI.flags[:f].aliases.include? :flag
    assert GLI.switches[:s].aliases.include? :'some-switch'
  end

  def test_flag_with_space_barfs
    GLI.reset
    assert_raises(ArgumentError) { GLI.flag ['some flag'] }
    assert_raises(ArgumentError) { GLI.flag ['f','some flag'] }
    assert_raises(ArgumentError) { GLI.switch ['some switch'] }
    assert_raises(ArgumentError) { GLI.switch ['f','some switch'] }
    assert_raises(ArgumentError) { GLI.command ['some command'] }
    assert_raises(ArgumentError) { GLI.command ['f','some command'] }
  end

  def test_init_from_config
    failure = nil
    GLI.reset
    GLI.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml'))
    GLI.flag :f
    GLI.switch :s
    GLI.flag :g
    called = false
    GLI.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          called = true
          assert_equal "foo",g[:f]
          assert_equal "bar",o[:g]
          assert !g[:g]
          assert !o[:f]
          assert !g[:s]
          assert o[:s]
        rescue Exception => ex
          failure = ex
        end
      end
    end
    GLI.run(['command'])
    assert called
    raise failure if !failure.nil?
  end

  def test_command_line_overrides_config
    failure = nil
    GLI.reset
    GLI.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml'))
    GLI.flag :f
    GLI.switch :s
    GLI.flag :g
    called = false
    GLI.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          called = true
          assert_equal "baaz",o[:g]
          assert_equal "bar",g[:f]
          assert !g[:g]
          assert !o[:f]
          assert !g[:s]
          assert o[:s]
        rescue Exception => ex
          failure = ex
        end
      end
    end
    GLI.run %w(-f bar command -g baaz)
    assert called
    raise failure if !failure.nil?
  end

  def test_no_overwrite_config
    config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml')
    config_file_contents = read_file_contents(config_file)
    GLI.reset
    GLI.config_file(config_file)
    ex = assert_raises RuntimeError do
      GLI.run(['initconfig'])
    end
    assert_match /--force/,ex.to_s,"Error message didn't mention --force option"
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
    long_desc = 'this is a very long description'
    object.desc description
    object.long_desc long_desc
    object.arg_name 'filename'
    object.default_value '~/.blah.rc'
    object.flag :f
    assert (object.flags[:f] )
    assert_equal(description,object.flags[:f].description)
    assert_equal(long_desc,object.flags[:f].long_description)
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
    long_description = 'this is a very long description'
    object.desc description
    object.long_desc long_description
    object.switch :f
    assert (object.switches[:f] )
    assert_equal(description,object.switches[:f].description)
    assert_equal(long_description,object.switches[:f].long_description)
    assert(object.usage != nil) if object.respond_to? :usage;
  end

  def test_switch_create_twice
    GLI.reset
    do_test_switch_create_twice(GLI)
    do_test_switch_create_twice(Command.new(:f,'Some command'))
  end

  def test_all_aliases_in_options
    GLI.reset
    GLI.on_error { |ex| raise ex }
    GLI.flag [:f,:flag,:'big-flag-name']
    GLI.switch [:s,:switch,:'big-switch-name']
    GLI.command [:com,:command] do |c|
      c.flag [:g,:gflag]
      c.switch [:h,:hswitch]
      c.action do |global,options,args|
        assert_equal 'foo',global[:f]
        assert_equal global[:f],global[:flag]
        assert_equal global[:f],global[:'big-flag-name']

        assert global[:s]
        assert global[:switch]
        assert global[:'big-switch-name']

        assert_equal 'bar',options[:g]
        assert_equal options[:g],options[:gflag]

        assert options[:h]
        assert options[:hswitch]
      end
    end
    GLI.run(%w(-f foo -s command -g bar -h some_arg))
  end

  def test_use_hash_by_default
    GLI.reset
    GLI.switch :g
    GLI.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal Hash,global.class
        assert_equal Hash,options.class
      end
    end
    GLI.run(%w(-g command -f))
  end

  def test_use_openstruct
    GLI.reset
    GLI.switch :g
    GLI.use_openstruct true
    GLI.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal GLI::Options,global.class
        assert_equal GLI::Options,options.class
      end
    end
    GLI.run(%w(-g command -f))
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

  def test_repeated_option_names
    GLI.reset
    GLI.on_error { |ex| raise ex }
    GLI.flag [:f,:flag]
    assert_raises(ArgumentError) { GLI.switch [:foo,:flag] }
    assert_raises(ArgumentError) { GLI.switch [:f] }

    GLI.switch [:x,:y]
    assert_raises(ArgumentError) { GLI.flag [:x] }
    assert_raises(ArgumentError) { GLI.flag [:y] }
  end

  def test_repeated_option_names_on_command
    GLI.reset
    GLI.on_error { |ex| raise ex }
    GLI.command :command do |c|
      c.flag [:f,:flag]
      assert_raises(ArgumentError) { c.switch [:foo,:flag] }
      assert_raises(ArgumentError) { c.switch [:f] }
      assert_raises(ArgumentError) { c.flag [:foo,:flag] }
      assert_raises(ArgumentError) { c.flag [:f] }
    end
    GLI.command :command3 do |c|
      c.switch [:s,:switch]
      assert_raises(ArgumentError) { c.switch [:switch] }
      assert_raises(ArgumentError) { c.switch [:s] }
      assert_raises(ArgumentError) { c.flag [:switch] }
      assert_raises(ArgumentError) { c.flag [:s] }
    end
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

  def test_exits_zero_on_success
    assert_equal 0,GLI.run([])
  end

  def test_exits_nonzero_on_bad_command_line
    GLI.reset
    GLI.on_error { true }
    assert_equal -1,GLI.run(['asdfasdfasdf'])
  end

  def test_exists_nonzero_on_raise_from_command
    GLI.reset
    GLI.on_error { true }
    GLI.command(:foo) do |c|
      c.action do |g,o,a|
        raise "Problem"
      end
    end
    assert_equal -2,GLI.run(['foo'])
  end

  def test_exits_nonzero_with_custom_exception
    GLI.reset
    GLI.on_error { true }
    GLI.command(:foo) do |c|
      c.action do |g,o,a|
        raise CustomExit.new("Problem",45)
      end
    end
    assert_equal 45,GLI.run(['foo'])
  end

  def test_exits_nonzero_with_exit_method
    GLI.reset
    GLI.on_error { true }
    GLI.command(:foo) do |c|
      c.action do |g,o,a|
        exit_now!("Problem",45)
      end
    end
    assert_equal 45,GLI.run(['foo'])
  end

  def test_gli_debug_overrides_error_hiding
    ENV['GLI_DEBUG'] = 'true'

    GLI.reset
    GLI.on_error { true }
    GLI.command(:foo) do |c|
      c.action do |g,o,a|
        exit_now!("Problem",45)
      end
    end

    assert_raises(CustomExit) { GLI.run(['foo']) }
  end

  private

  def read_file_contents(filename)
    contents = ""
    File.open(filename) { |file| file.readlines.each { |line| contents += line }}
    contents
  end

end
