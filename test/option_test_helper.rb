module OptionTestHelper
  def name_should_be(name)
    lambda {
      assert_equal(name,@cli_option.name)
    }
  end

  def aliases_should_be(aliases)
    lambda {
      assert_equal(aliases,@cli_option.aliases)
    }
  end
end
