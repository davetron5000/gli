require 'gli'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include GLI
class TC_testGLI < Test::Unit::TestCase

  def test_flag_create
    description = 'this is a description'
    GLI.desc description
    arg_name 'filename'
    default_value '~/.blah.rc'
    flag :f
    assert (flages[:f] )
    assert_equal(description,flages[:f].description)
    assert_equal("-f filename - #{description} (default ~/.blah.rc)",flages[:f].usage)
  end

  def test_switch_create
    description = 'this is a description'
    GLI.desc description
    switch :f
    assert (switchs[:f] )
    assert_equal(description,switchs[:f].description)
  end

  def test_switch_create_twice
    description = 'this is a description'
    GLI.desc description
    switch :f
    assert (switchs[:f] )
    assert_equal(description,switchs[:f].description)
    switch :g
    assert (switchs[:g])
    assert_equal(nil,switchs[:g].description)
  end
end
