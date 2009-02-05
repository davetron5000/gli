require 'rake/clean'
require 'hanna/rdoctask'
require 'rcov/rcovtask'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
$: << '../grancher/lib'
require 'grancher/task'

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.directory 'html'
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Git Like Interface'
end

spec = eval(File.read('gli.gemspec'))
$: << 'lib'
require 'gli'
raise "Version mismatch" if spec.version != GLI::VERSION

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
