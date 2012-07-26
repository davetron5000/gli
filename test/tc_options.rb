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

  def test_map_defers_to_underlying_map
    o = Options.new
    o[:foo] = 'bar'
    o[:blah] = 'crud'

    result = Hash[o.map { |k,v|
      [k,v.upcase]
    }]
    assert_equal 2,result.size
    assert_equal "BAR",result[:foo]
    assert_equal "CRUD",result[:blah]
  end

end
