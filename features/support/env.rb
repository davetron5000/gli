require 'aruba/cucumber'
require 'fileutils'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
GLI_LIB_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..','..','lib'))

GLI_GEMSET = 'gli-testing'
TMP_PATH = 'tmp/aruba'

Before do
  # Not sure how else to get this dynamically
  @dirs = [TMP_PATH]
end

After do |scenario|
  ENV['RUBYLIB'] = ''
  todo_app_dir = File.join(TMP_PATH,'todo')
  if File.exists? todo_app_dir
    FileUtils.rm_rf(todo_app_dir)
  end
end
