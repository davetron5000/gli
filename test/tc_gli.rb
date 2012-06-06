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

require 'test_helper'

class TC_testGLI < Clean::Test::TestCase
  include TestHelper
  include GLI

  def setup
    @app = CLIApp.new
    @config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/new_config.yaml')
    @gli_debug = ENV['GLI_DEBUG']
    @fake_stderr = FakeStdOut.new
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')
  end

  def teardown
    File.delete(@config_file) if File.exist?(@config_file)
    ENV['GLI_DEBUG'] = @gli_debug
    @app.error_device=$stderr
  end

  def test_flag_create
    @app.reset
    do_test_flag_create(@app)
    do_test_flag_create(Command.new(:names => :f))
  end

  def test_create_commands_using_strings
    @app.reset
    @app.flag ['f','flag']
    @app.switch ['s','some-switch']
    @app.command 'command','command-with-dash' do |c|
    end
    assert @app.commands.include? :command
    assert @app.flags.include? :f
    assert @app.switches.include? :s
    assert @app.commands[:command].aliases.include? :'command-with-dash'
    assert @app.flags[:f].aliases.include? :flag
    assert @app.switches[:s].aliases.include? :'some-switch'
  end

  def test_default_command
    @app.reset
    @called = false
    @app.command :foo do |c|
      c.action do |global, options, arguments|
        @called = true
      end
    end
    @app.default_command(:foo)
    assert_equal 0, @app.run([]), "Expected exit status to be 0"
    assert @called, "Expected default command to be executed"
  end

  def test_flag_with_space_barfs
    @app.reset
    assert_raises(ArgumentError) { @app.flag ['some flag'] }
    assert_raises(ArgumentError) { @app.flag ['f','some flag'] }
    assert_raises(ArgumentError) { @app.switch ['some switch'] }
    assert_raises(ArgumentError) { @app.switch ['f','some switch'] }
    assert_raises(ArgumentError) { @app.command ['some command'] }
    assert_raises(ArgumentError) { @app.command ['f','some command'] }
  end

  def test_init_from_config
    failure = nil
    @app.reset
    @app.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml'))
    @app.flag :f
    @app.switch :s
    @app.flag :g
    called = false
    @app.command :command do |c|
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
    @app.run(['command'])
    assert called
    raise failure if !failure.nil?
  end

  def test_command_line_overrides_config
    failure = nil
    @app.reset
    @app.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml'))
    @app.flag :f
    @app.switch :s
    @app.flag :g
    @app.switch :bleorgh
    called = false
    @app.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          called = true
          assert_equal "baaz",o[:g]
          assert_equal "bar",g[:f]
          assert !g[:g],o.inspect
          assert !o[:f],o.inspect
          assert !g[:s],o.inspect
          assert o[:s],o.inspect
          assert g[:bleorgh] != nil,"Expected :bleorgh to have a value"
          assert g[:bleorgh] == false,"Expected :bleorgh to be false"
        rescue Exception => ex
          failure = ex
        end
      end
    end
    assert_equal 0,@app.run(%w(-f bar --no-bleorgh command -g baaz)),@fake_stderr.to_s
    assert called
    raise failure if !failure.nil?
  end

  def test_no_overwrite_config
    config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/config.yaml')
    config_file_contents = File.read(config_file)
    @app.reset
    @app.config_file(config_file)
    assert_equal 1,@app.run(['initconfig'])
    assert @fake_stderr.strings.grep(/--force/),@fake_stderr.strings.inspect
    config_file_contents_after = File.read(config_file)
    assert_equal(config_file_contents,config_file_contents_after)
  end

  def test_config_file_name
    @app.reset
    file = @app.config_file("foo")
    assert_equal(Etc.getpwuid.dir + "/foo",file)
    file = @app.config_file("/foo")
    assert_equal "/foo",file
    init_command = @app.commands[:initconfig]
    assert init_command
  end

  def test_initconfig_command
    @app.reset
    @app.config_file(@config_file)
    @app.flag :f
    @app.switch :s
    @app.switch :w
    @app.flag :bigflag
    @app.flag :biggestflag
    @app.command :foo do |c|
    end
    @app.command :bar do |c|
    end
    @app.command :blah do |c|
    end
    @app.on_error do |ex|
      raise ex
    end
    @app.run(['-f','foo','-s','--bigflag=bleorgh','initconfig'])

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

  def test_initconfig_permissions
    @app.reset
    @app.config_file(@config_file)
    @app.run(['initconfig'])
    oct_mode = "%o" % File.stat(@config_file).mode
    assert_match /0600$/, oct_mode
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
    @app.reset
    do_test_switch_create(@app)
    do_test_switch_create(Command.new(:names => :f))
  end

  def test_switch_create_twice
    @app.reset
    do_test_switch_create_twice(@app)
    do_test_switch_create_twice(Command.new(:names => :f))
  end

  def test_all_aliases_in_options
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.flag [:f,:flag,:'big-flag-name']
    @app.switch [:s,:switch,:'big-switch-name']
    @app.command [:com,:command] do |c|
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
    @app.run(%w(-f foo -s command -g bar -h some_arg))
  end

  def test_use_hash_by_default
    @app.reset
    @app.switch :g
    @app.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal Hash,global.class
        assert_equal Hash,options.class
      end
    end
    @app.run(%w(-g command -f))
  end

  def test_flag_array_of_options_global
    @app.reset
    @app.flag :foo, :must_match => ['bar','blah','baz']
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
    assert_equal 0,@app.run(%w(--foo=blah command)),@fake_stderr.to_s
  end

  def test_flag_hash_of_options_global
    @app.reset
    @app.flag :foo, :must_match => { 'bar' => "BAR", 'blah' => "BLAH" }
    @foo_arg_value = nil
    @app.command :command do |c|
      c.action do |g,o,a|
        @foo_arg_value = g[:foo]
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
    assert_equal 0,@app.run(%w(--foo=blah command)),@fake_stderr.to_s
    assert_equal 'BLAH',@foo_arg_value
  end

  def test_flag_regexp_global
    @app.reset
    @app.flag :foo, :must_match => /bar/
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_flag_regexp_global_short_form
    @app.reset
    @app.flag :f, :must_match => /bar/
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(-f cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: -f cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_flag_regexp_command
    @app.reset
    @app.command :command do |c|
      c.flag :foo, :must_match => /bar/
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(command --foo=cruddo)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_use_openstruct
    @app.reset
    @app.switch :g
    @app.use_openstruct true
    @app.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal GLI::Options,global.class
        assert_equal GLI::Options,options.class
      end
    end
    @app.run(%w(-g command -f))
  end

  def test_repeated_option_names
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.flag [:f,:flag]
    assert_raises(ArgumentError) { @app.switch [:foo,:flag] }
    assert_raises(ArgumentError) { @app.switch [:f] }

    @app.switch [:x,:y]
    assert_raises(ArgumentError) { @app.flag [:x] }
    assert_raises(ArgumentError) { @app.flag [:y] }

    # This shouldn't raise; :help is special
    @app.switch :help
  end

  def test_repeated_option_names_on_command
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.command :command do |c|
      c.flag [:f,:flag]
      assert_raises(ArgumentError) { c.switch [:foo,:flag] }
      assert_raises(ArgumentError) { c.switch [:f] }
      assert_raises(ArgumentError) { c.flag [:foo,:flag] }
      assert_raises(ArgumentError) { c.flag [:f] }
    end
    @app.command :command3 do |c|
      c.switch [:s,:switch]
      assert_raises(ArgumentError) { c.switch [:switch] }
      assert_raises(ArgumentError) { c.switch [:s] }
      assert_raises(ArgumentError) { c.flag [:switch] }
      assert_raises(ArgumentError) { c.flag [:s] }
    end
  end

  def test_two_flags
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    @app.run(['foo', '-i','5','-s','a'])
  end

  def test_two_flags_with_a_default
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    @app.run(['foo', '-i','5','-s','a'])
  end

  def test_two_flags_using_equals_with_a_default
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i],o.inspect
        assert_equal "a", o[:s],o.inspect
      end
    end
    @app.run(['foo', '-i5','-sa'])
  end

  def test_exits_zero_on_success
    assert_equal 0,@app.run([]),@fake_stderr.to_s
  end

  def test_exits_nonzero_on_bad_command_line
    @app.reset
    @app.on_error { true }
    assert_equal 64,@app.run(['asdfasdfasdf'])
  end

  def test_exists_nonzero_on_raise_from_command
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise "Problem"
      end
    end
    assert_equal 1,@app.run(['foo'])
  end

  def test_exits_nonzero_with_custom_exception
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise CustomExit.new("Problem",45)
      end
    end
    assert_equal 45,@app.run(['foo'])
  end

  def test_exits_nonzero_with_exit_method
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem",45)
      end
    end
    assert_equal 45,@app.run(['foo'])
  end

  def test_exits_nonzero_with_exit_method_by_default
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem")
      end
    end
    assert_equal 1,@app.run(['foo'])
  end

  def test_help_now_exits_and_shows_help
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.help_now!("Problem")
      end
    end
    assert_equal 64,@app.run(['foo']),@fake_stderr.strings.join("\n")
  end

  def test_custom_exception_causes_error_to_be_printed_to_stderr
    @app.reset
    @app.on_error { true }
    error_message = "Something went wrong"
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise error_message
      end
    end
    @app.run(['foo'])
    assert @fake_stderr.strings.include?("error: #{error_message}"),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_gli_debug_overrides_error_hiding
    ENV['GLI_DEBUG'] = 'true'

    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem",45)
      end
    end

    assert_raises(CustomExit) { @app.run(['foo']) }
  end

  class ConvertMe
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  def test_that_we_can_add_new_casts_for_flags
    @app.reset
    @app.accept(ConvertMe) do |value|
      ConvertMe.new(value)
    end
    @app.flag :foo, :type => ConvertMe

    @foo = nil
    @baz = nil

    @app.command(:bar) do |c|
      c.flag :baz, :type => ConvertMe
      c.action do |g,o,a|
        @foo = g[:foo]
        @baz = o[:baz]
      end
    end

    assert_equal 0,@app.run(['--foo','blah','bar','--baz=crud']),@fake_stderr.to_s

    assert @foo.kind_of?(ConvertMe),"Expected a ConvertMe, but get a #{@foo.class}"
    assert_equal 'blah',@foo.value

    assert @baz.kind_of?(ConvertMe),"Expected a ConvertMe, but get a #{@foo.class}"
    assert_equal 'crud',@baz.value
  end

  private

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
    assert(object.usage != nil) if object.respond_to? :usage
  end

  def do_test_switch_create(object)
    do_test_switch_create_classic(object)
    do_test_switch_create_compact(object)
  end

  def some_descriptions
    lambda {
      @description = 'this is a description'
      @long_description = 'this is a very long description'
    }
  end

  def assert_switch_was_made(object,switch) 
    lambda {
      assert object.switches[switch]
      assert_equal @description,object.switches[switch].description,"For switch #{switch}"
      assert_equal @long_description,object.switches[switch].long_description,"For switch #{switch}"
      assert(object.usage != nil) if object.respond_to? :usage
    }
  end

  def do_test_switch_create_classic(object)
    Given some_descriptions
    When {
      object.desc @description
      object.long_desc @long_description
      object.switch :f
    }
    Then assert_switch_was_made(object,:f)
  end

  def do_test_switch_create_compact(object)
    Given some_descriptions
    When {
      object.switch :g, :desc => @description, :long_desc => @long_description
    }
    Then assert_switch_was_made(object,:g)
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
    assert(object.usage != nil) if object.respond_to? :usage
  end


end
