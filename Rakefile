require 'rake/clean'
require 'rcov/rcovtask'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'sdoc'
require 'grancher/task'

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

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
end


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

desc "Generates the changelog from annotated tags"
task :changelog do
  raise "You must check out gli.wiki to this directory first" unless File.exists? 'gli.wiki'
  log = `git tag -n100`
  start = false
  version = nil
  message = nil
  changelog = {}
  log.split(/\n/).each do |line|
    start = true if line =~ /v1.1.3/
    next unless start
    if line =~ /^v/
      changelog[version] = message unless version.nil?
      version,message = line.split(/\s+/,2)
    else
      message += "\n" + line.strip
    end
  end
  File.open('gli.wiki/Changelog.md','w') do |file|
    changelog[version] = message
    changelog.keys.sort.reverse.each do |version|
      dates = `git show #{version} | grep ^Date`
      date_parts = dates.split(/\n/)[-1].split
      file.puts "## #{version} - #{date_parts[2]} #{date_parts[3]} #{date_parts[5]}"
      file.puts
      file.puts changelog[version]
      file.puts 
    end
  end
  `cd gli.wiki ; git commit -a -m 'updated changelog' ; git push origin master; cd -`
end

desc 'Publish rdoc on github pages and push to github'
task :publish_rdoc => [:rdoc,:publish]

task :default => :test

