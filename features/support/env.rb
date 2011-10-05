require 'aruba/cucumber'
require 'fileutils'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
PROJECT_ROOT = File.join(File.dirname(__FILE__),'..','..')
GLI_LIB_PATH = File.expand_path(File.join(PROJECT_ROOT,'lib'))

GLI_GEMSET = 'gli-testing'
TMP_PATH = 'tmp/aruba'

Before do
  # Not sure how else to get this dynamically
  @dirs = [TMP_PATH]
  @aruba_timeout_seconds = 5
  @original_rubylib = ENV['RUBYLIB']
  prepend_to_load_path(GLI_LIB_PATH)
end

After do |scenario|
  ENV['RUBYLIB'] = @original_rubylib
  todo_app_dir = File.join(TMP_PATH,'todo')
  if File.exists? todo_app_dir
    FileUtils.rm_rf(todo_app_dir)
  end
end

def prepend_to_load_path(path)
  ENV['RUBYLIB'] = path + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end
