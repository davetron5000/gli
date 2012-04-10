require 'test_helper'

class TC_testOptions < Clean::Test::TestCase
  include TestHelper
  include GLI

  def test_by_method
    o = Options.new
    o.name = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end
  
  def test_by_string
    o = Options.new
    o['name'] = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end
  
  def test_by_symbol
    o = Options.new
    o[:name] = 'verbose'
    assert_equal 'verbose', o.name
    assert_equal 'verbose', o[:name]
    assert_equal 'verbose', o['name']
  end

end
