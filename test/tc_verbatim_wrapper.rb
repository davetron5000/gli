require 'test_helper'

class TC_testVerbatimWrapper < Clean::Test::TestCase
  include TestHelper

  test_that "verbatim wrapper handles nil" do
    Given {
      @wrapper = GLI::Commands::HelpModules::VerbatimWrapper.new(any_int,any_int)
    }
    When {
      @result = @wrapper.wrap(nil)
    }
    Then {
      assert_equal '',@result
    }
  end

  test_that "verbatim wrapper doesn't touch the input" do
    Given {
      @wrapper = GLI::Commands::HelpModules::VerbatimWrapper.new(any_int,any_int)
      @input = <<EOS
      |This is|an ASCII|table|
      +-------+--------+-----+
      | foo   |  bar   | baz |
      +-------+--------+-----+
EOS
    }
    When {
      @result = @wrapper.wrap(@input)
    }
    Then {
      assert_equal @input,@result
    }
  end

end
