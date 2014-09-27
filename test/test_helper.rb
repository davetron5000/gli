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

    def reset
      super
      @subcommand_option_handling_strategy = :normal
    end
  end
end

Faker::Config.locale = :en
I18n.enforce_available_locales = false
