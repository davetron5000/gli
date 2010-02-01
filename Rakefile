require 'rake/clean'
require 'rcov/rcovtask'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'sdoc'

$: << '../grancher/lib'
begin
  require 'grancher/task'
  Grancher::Task.new do |g|
    g.branch = 'gh-pages'
    g.push_to = 'origin'
    g.directory 'html'
  end
rescue LoadError
  #puts "you may install the optional gem 'grancher'"
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.options << '--fmt' << 'shtml'
  rd.template = 'direct'
  rd.title = 'Git Like Interface'
end

spec = eval(File.read('gli.gemspec'))

Rake::GemPackageTask.new(spec) do |pkg|
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
end


task :clobber_coverage do
  rm_rf "coverage"
end

desc 'Measures test coverage'
task :coverage => :rcov do
  system("open coverage/index.html") if PLATFORM['darwin']
  rm output_yaml
end

Rcov::RcovTask.new do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/tc_*.rb']
end

task :default => :test

task :publish_rdoc => [:rdoc,:publish]
