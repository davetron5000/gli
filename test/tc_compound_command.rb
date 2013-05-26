require 'test_helper'
require 'tempfile'

class TC_testCompounCommand < Clean::Test::TestCase
  include TestHelper

  test_that "when we create a CompoundCommand where some commands are missing, we get an exception" do
    Given {
      @name = any_string
      @unknown_name = any_string
      @existing_command = OpenStruct.new(:name => @name)
      @base = OpenStruct.new( :commands => { @name => @existing_command })
    }
    When {
      @code = lambda { GLI::Commands::CompoundCommand.new(@base,{:foo => [@name,@unknown_name]}) }
    }
    Then {
      ex = assert_raises(RuntimeError,&@code)
      assert_match /#{@unknown_name}/,ex.message
    }
  end
end
