require 'sdoc'
require 'bundler'
require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'
require 'cucumber'
require 'cucumber/rake/task'

include Rake::DSL

CLEAN << "log"
CLOBBER << FileList['**/*.rbc']


task :rdoc => [:build_rdoc, :hack_css]
Rake::RDocTask.new(:build_rdoc) do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files = FileList["lib/**/*.rb","README.rdoc"] - 
                  FileList["lib/gli/commands/help_modules/*.rb"] - 
                  ["lib/gli/commands/help.rb",
                   "lib/gli/commands/scaffold.rb",
                   "lib/gli/support/*.rb",
                   "lib/gli/app_support.rb",
                   "lib/gli/option_parser_factory.rb",
                   "lib/gli/gli_option_parser.rb",
                   "lib/gli/command_support.rb",]
  rd.title = 'GLI - Git Like Interface for your command-line apps'
  rd.options << '-f' << 'sdoc'
  rd.template = 'direct'
end

FONT_FIX = {
  "0.82em" => "16px",
  "0.833em" => "16px",
  "0.85em" => "16px",
  "1.15em" => "20px",
  "1.1em" => "20px",
  "1.2em" => "20px",
  "1.4em" => "24px",
  "1.5em" => "24px",
  "1.6em" => "32px",
  "1em" => "16px",
  "2.1em" => "38px",
}


task :hack_css do
  maincss = File.open('html/css/main.css').readlines
  File.open('html/css/main.css','w') do |file|
    file.puts '@import url(http://fonts.googleapis.com/css?family=Karla:400,700,400italic,700italic|Alegreya);'
    
    maincss.each do |line|
      if line.strip == 'font-family: "Helvetica Neue", Arial, sans-serif;'
        file.puts 'font-family: Karla, "Helvetica Neue", Arial, sans-serif;'
      elsif line.strip == 'font-family: monospace;'
        file.puts 'font-family: Monaco, monospace;'
      elsif line =~ /^pre\s*$/
        file.puts "pre {
          font-family: Monaco, monospace;
          margin-bottom: 1em;
        }
        pre.original"
      elsif line =~ /^\s*font-size:\s*(.*)\s*;/
        if FONT_FIX[$1]
          file.puts "font-size: #{FONT_FIX[$1]};"
        else
          file.puts line.chomp
        end
      else
        file.puts line.chomp
      end
    end
  end
end

Bundler::GemHelper.install_tasks

desc 'run unit tests'
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

task :default => [:test,:features]

