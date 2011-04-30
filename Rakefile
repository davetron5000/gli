require 'rake/clean'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'sdoc'
require 'grancher/task'
require 'reek/rake/task'
require 'roodi'
require 'roodi_task'
require 'cucumber'
require 'cucumber/rake/task'

CLEAN << "cruddo.rdoc"
CLEAN << "log"
CLOBBER << FileList['**/*.rbc']

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.directory 'html'
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

Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.config_files = ['test/gli.reek']
  t.source_files = FileList['lib/**/*.rb'] - FileList['lib/support/*.rb']
end

RoodiTask.new do |t|
  t.patterns = ['lib/*.rb','lib/gli/*.rb']
  t.config = 'test/roodi.yaml'
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
end

CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format progress -x"
  t.fork = false
end

begin
  require 'rcov/rcovtask'
  task :clobber_coverage do
    rm_rf "coverage"
  end

  desc 'Measures test coverage'
  task :coverage => :rcov do
    puts "coverage/index.html contains what you need"
  end

  Rcov::RcovTask.new do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/tc_*.rb']
  end
rescue LoadError
  $stderr.puts "rcov not installed; you won't be able to check code coverage"
  $stderr.puts "Since rcov only works on MRI 1.8.7, this shouldn't be a problem"
end

desc 'Publish rdoc on github pages and push to github'
task :publish_rdoc => [:rdoc,:publish]

task :default => [:test,:features,:roodi,:reek]

