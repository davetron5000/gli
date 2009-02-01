require 'rake/clean'
require 'hanna/rdoctask'
require 'rcov/rcovtask'
require 'rubygems'
#require 'rake/gempackagetask'
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
  rd.title = 'Ruby Client for Gliffy'
end
 
# spec = eval(File.read('gliffy.gemspec'))
#  
# Rake::GemPackageTask.new(spec) do |pkg|
#     pkg.need_tar = true
# end
# 

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
#  t.verbose = true
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
  t.libs << 'ext'
  t.test_files = FileList['test/tc_*.rb']
  # t.verbose = true     # uncomment to see the executed command
end

task :default => :test

task :publish_rdoc => [:rdoc,:publish]
