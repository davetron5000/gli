require 'aruba/cucumber'
require 'fileutils'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

GLI_GEMSET = 'gli-testing'
TMP_PATH = 'tmp/aruba'

Before do
  # Not sure how else to get this dynamically
  @dirs = [TMP_PATH]
end

After do |scenario|
  todo_app_dir = File.join(TMP_PATH,'todo')
  if File.exists? todo_app_dir
    FileUtils.rm_rf(todo_app_dir)
  end

  command = %{rvm --force gemset delete "#{GLI_GEMSET}"}
  #run_simple(command, true)
end

def fail_if_output_didnt_match!(command,expecting)
  output = output_from(command)
  unless output =~ expecting
    #raise "Got unexpected output from #{command}:\n'#{output}'\nexpected:\n#{expecting}"
  end
end
