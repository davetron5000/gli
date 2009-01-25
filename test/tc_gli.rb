require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def test_switch_create
    description = 'this is a description'
    GLI.desc description
    switch :f
    assert (switches[:f] )
    assert_equal(description,switches[:f].description)
  end

  def test_flag_create
    description = 'this is a description'
    GLI.desc description
    flag :f
    assert (flags[:f] )
    assert_equal(description,flags[:f].description)
  end

  def test_flag_create_twice
    description = 'this is a description'
    GLI.desc description
    flag :f
    assert (flags[:f] )
    assert_equal(description,flags[:f].description)
    flag :g
    assert (flags[:g])
    assert_equal(nil,flags[:g].description)
  end
end
