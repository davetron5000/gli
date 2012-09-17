require 'rubygems'
require 'gli.rb'
require 'test/unit'
require 'clean_test/test_case'
require 'fake_std_out'
require 'option_test_helper'

module TestHelper
  include OptionTestHelper
  class CLIApp
    include GLI::App
  end
end

Faker::Config.locale = :en
