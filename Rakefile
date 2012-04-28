if RUBY_VERSION =~ /^1.9/
  require 'psych'
end
gem 'rdoc'
gem 'rake'
require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'
require 'grancher/task'
require 'roodi'
require 'roodi_task'
require 'cucumber'
require 'cucumber/rake/task'

include Rake::DSL
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
  rd.title = 'Git Like Interface'
end

spec = eval(File.read('gli.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

RoodiTask.new do |t|
  t.patterns = ['lib/*.rb','lib/gli/*.rb']
  t.config = 'test/roodi.yaml'
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/init_simplecov.rb','test/tc_*.rb']
end

CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  opts = "features --format html -o #{CUKE_RESULTS} --format progress -x"
  opts += " --tags #{ENV['TAGS']}" if ENV['TAGS']
  t.cucumber_opts =  opts
  t.fork = false
end
Cucumber::Rake::Task.new('features:wip') do |t|
  tag_opts = ' --tags ~@pending'
  tag_opts = ' --tags @wip'
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty -x -s#{tag_opts}"
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
  begin
    require 'simplecov'
  rescue LoadError
    $stderr.puts "neither rcov nor simplecov are installed; you won't be able to check code coverage"
  end
end

desc 'Publish rdoc on github pages and push to github'
task :publish_rdoc => [:rdoc,:publish]

task :default => [:test,:features,:roodi]

