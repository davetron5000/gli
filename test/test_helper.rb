require 'gli.rb'
require 'test/unit'
require 'test/unit/given'
require 'fake_std_out'
require 'option_test_helper'

module TestHelper
  include OptionTestHelper
  class CLIApp
    include GLI::App
  end
end
