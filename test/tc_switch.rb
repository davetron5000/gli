require 'test_helper'

class TC_testSwitch < Clean::Test::TestCase
  include TestHelper

  def test_basics_simple
    Given switch_with_names(:filename)
    Then attributes_should_be_set
    And name_should_be(:filename)
    And aliases_should_be(nil)
  end

  def test_basics_kinda_complex
    Given switch_with_names([:f])
    Then attributes_should_be_set
    And name_should_be(:f)
    And aliases_should_be(nil)
  end

  def test_basics_complex
    Given switch_with_names([:f,:file,:filename])
    Then attributes_should_be_set
    And name_should_be(:f)
    And aliases_should_be([:file,:filename])
    And {
      assert_equal ["-f","--[no-]file","--[no-]filename"],@switch.arguments_for_option_parser
    }
  end

  def test_includes_negatable
    assert_equal '-a',GLI::Switch.name_as_string('a')
    assert_equal '--[no-]foo',GLI::Switch.name_as_string('foo')
  end

  private 

  def switch_with_names(names)
    lambda do
      @options = {
        :desc => 'Filename',
        :long_desc => 'The Filename',
      }
      @switch = GLI::Switch.new(names,@options)
      @cli_option = @switch
    end
  end

  def attributes_should_be_set
    lambda {
      assert_equal(@options[:desc],@switch.description)
      assert_equal(@options[:long_desc],@switch.long_description)
    }
  end

end
