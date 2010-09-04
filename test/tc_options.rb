require 'gli.rb'
require 'test/unit'

include GLI
class TC_testOptions < Test::Unit::TestCase

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
