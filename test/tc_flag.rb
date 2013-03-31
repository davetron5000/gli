require 'test_helper'

class TC_testFlag < Clean::Test::TestCase
  include TestHelper

  def test_basics_simple
    Given flag_with_names(:f)
    Then attributes_should_be_set
    And name_should_be(:f)
    And aliases_should_be(nil)
  end

  def test_basics_kinda_complex
    Given flag_with_names([:f])
    Then attributes_should_be_set
    And name_should_be(:f)
    And aliases_should_be(nil)
  end

  def test_basics_complex
    Given flag_with_names([:f,:file,:filename])
    Then attributes_should_be_set
    And name_should_be(:f)
    And aliases_should_be([:file,:filename])
    And {
      assert_equal ["-f VAL","--file VAL","--filename VAL",/foobar/,Float],@flag.arguments_for_option_parser
    }
  end

  def test_flag_can_mask_its_value
    Given flag_with_names(:password, :mask => true)
    Then attributes_should_be_set(:safe_default_value => "********")
  end

  def flag_with_names(names,options = {})
    lambda do
      @options = {
        :desc => 'Filename',
        :long_desc => 'The Filename',
        :arg_name => 'file',
        :default_value => '~/.blah.rc',
        :safe_default_value => '~/.blah.rc',
        :must_match => /foobar/,
        :type => Float,
      }.merge(options)
      @flag = GLI::Flag.new(names,@options)
      @cli_option = @flag
    end
  end

  def attributes_should_be_set(override={})
    lambda {
      expected = @options.merge(override)
      assert_equal(expected[:desc],@flag.description)
      assert_equal(expected[:long_desc],@flag.long_description)
      assert_equal(expected[:default_value],@flag.default_value)
      assert_equal(expected[:safe_default_value],@flag.safe_default_value)
      assert_equal(expected[:must_match],@flag.must_match)
      assert_equal(expected[:type],@flag.type)
    }
  end
end
