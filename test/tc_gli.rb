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
    assert (flags[:f] )
    assert_equal(description,flags[:f].description)
    assert_equal("-f filename - #{description} (default ~/.blah.rc)",flags[:f].usage)
  end

  def test_switch_create
    description = 'this is a description'
    GLI.desc description
    switch :f
    assert (switches[:f] )
    assert_equal(description,switches[:f].description)
  end

  def test_switch_create_twice
    description = 'this is a description'
    GLI.desc description
    switch :f
    assert (switches[:f] )
    assert_equal(description,switches[:f].description)
    switch :g
    assert (switches[:g])
    assert_equal(nil,switches[:g].description)
  end

  def test_command_create
    description = 'List all files'
    GLI.desc description
    GLI.command [:ls,:list] do |c|
    end
  end
end
