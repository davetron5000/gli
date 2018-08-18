require 'gli'
require 'fileutils'

module GLI
  module Commands
  class Scaffold #:nodoc:

    def self.create_scaffold(root_dir,
                             create_test_dir,
                             create_ext_dir,
                             project_name,
                             commands,
                             force=false,
                             dry_run=false,
                             create_rvmrc=false)
      dirs = [File.join(root_dir,project_name,'lib')]
      dirs << File.join(root_dir,project_name,'bin')
      dirs << File.join(root_dir,project_name,'test') if create_test_dir
      dirs << File.join(root_dir,project_name,'ext') if create_ext_dir

      if mkdirs(dirs,force,dry_run)
        mk_binfile(root_dir,create_ext_dir,force,dry_run,project_name,commands)
        mk_readme(root_dir,dry_run,project_name)
        mk_gemspec(root_dir,dry_run,project_name)
        mk_rakefile(root_dir,dry_run,project_name,create_test_dir)
        mk_lib_files(root_dir,dry_run,project_name)
        if create_rvmrc
          rvmrc = File.join(root_dir,project_name,".rvmrc")
          File.open(rvmrc,'w') do |file|
            file.puts "rvm use #{ENV['rvm_ruby_string']}@#{project_name} --create"
          end
          puts "Created #{rvmrc}"
        end
      end
    end

    def self.mk_readme(root_dir,dry_run,project_name)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/README.rdoc",'w') do |file|
        file << "= #{project_name}\n\n"
        file << "Describe your project here\n\n"
        file << ":include:#{project_name}.rdoc\n\n"
      end
      puts "Created #{root_dir}/#{project_name}/README.rdoc"
      File.open("#{root_dir}/#{project_name}/#{project_name}.rdoc",'w') do |file|
        file << "= #{project_name}\n\n"
        file << "Generate this with\n    #{project_name} _doc\nAfter you have described your command line interface"
      end
      puts "Created #{root_dir}/#{project_name}/#{project_name}.rdoc"
    end

    def self.mk_gemspec(root_dir,dry_run,project_name)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/#{project_name}.gemspec",'w') do |file|
        file.puts <<EOS
# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','#{project_name}','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = '#{project_name}'
  s.version = #{project_name_as_module_name(project_name)}::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.extra_rdoc_files = ['README.rdoc','#{project_name}.rdoc']
  s.rdoc_options << '--title' << '#{project_name}' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << '#{project_name}'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','#{GLI::VERSION}')
end
EOS
      end
      puts "Created #{root_dir}/#{project_name}/#{project_name}.gemspec"
    end

    def self.project_name_as_module_name(project_name)
      project_name.split(/[_-]/).map { |part| part[0..0].upcase + part[1..-1] }.join('')
    end

    def self.mk_lib_files(root_dir,dry_run,project_name)
      return if dry_run
      FileUtils.mkdir("#{root_dir}/#{project_name}/lib/#{project_name}")
      File.open("#{root_dir}/#{project_name}/lib/#{project_name}/version.rb",'w') do |file|
        file.puts <<EOS
module #{project_name_as_module_name(project_name)}
  VERSION = '0.0.1'
end
EOS
      end
      puts "Created #{root_dir}/#{project_name}/lib/#{project_name}/version.rb"
      File.open("#{root_dir}/#{project_name}/lib/#{project_name}.rb",'w') do |file|
        file.puts <<EOS
require '#{project_name}/version.rb'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file
EOS
      end
      puts "Created #{root_dir}/#{project_name}/lib/#{project_name}.rb"
    end
    def self.mk_rakefile(root_dir,dry_run,project_name,create_test_dir)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/Rakefile",'w') do |file|
        file.puts <<EOS
require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
EOS
        if create_test_dir
          file.puts <<EOS
require 'cucumber'
require 'cucumber/rake/task'
EOS
        end
        file.puts <<EOS
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('#{project_name}.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end
EOS
        if create_test_dir
          file.puts <<EOS
CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
desc 'Run features'
Cucumber::Rake::Task.new(:features) do |t|
  opts = "features --format html -o \#{CUKE_RESULTS} --format progress -x"
  opts += " --tags \#{ENV['TAGS']}" if ENV['TAGS']
  t.cucumber_opts =  opts
  t.fork = false
end

desc 'Run features tagged as work-in-progress (@wip)'
Cucumber::Rake::Task.new('features:wip') do |t|
  tag_opts = ' --tags ~@pending'
  tag_opts = ' --tags @wip'
  t.cucumber_opts = "features --format html -o \#{CUKE_RESULTS} --format pretty -x -s\#{tag_opts}"
  t.fork = false
end

task :cucumber => :features
task 'cucumber:wip' => 'features:wip'
task :wip => 'features:wip'
EOS
        end
        if create_test_dir
          file.puts <<EOS
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
end

task :default => [:test,:features]
EOS
          File.open("#{root_dir}/#{project_name}/test/default_test.rb",'w') do |test_file|
            test_file.puts <<EOS
require 'test_helper'

class DefaultTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_the_truth
    assert true
  end
end
EOS
          end
          puts "Created #{root_dir}/#{project_name}/test/default_test.rb"
          File.open("#{root_dir}/#{project_name}/test/test_helper.rb",'w') do |test_file|
            test_file.puts <<EOS
require 'test/unit'

# Add test libraries you want to use here, e.g. mocha

class Test::Unit::TestCase

  # Add global extensions to the test case class here

end
EOS
          end
          puts "Created #{root_dir}/#{project_name}/test/test_helper.rb"
        else
          file.puts "task :default => :package\n"
        end
      end
      puts "Created #{root_dir}/#{project_name}/Rakefile"
      File.open("#{root_dir}/#{project_name}/Gemfile",'w') do |bundler_file|
        bundler_file.puts "source 'https://rubygems.org'"
        bundler_file.puts "gemspec"
      end
      puts "Created #{root_dir}/#{project_name}/Gemfile"
      if create_test_dir
        features_dir = File.join(root_dir,project_name,'features')
        FileUtils.mkdir features_dir
        FileUtils.mkdir File.join(features_dir,"step_definitions")
        FileUtils.mkdir File.join(features_dir,"support")
        File.open(File.join(features_dir,"#{project_name}.feature"),'w') do |file|
          file.puts <<EOS
Feature: My bootstrapped app kinda works
  In order to get going on coding my awesome app
  I want to have aruba and cucumber setup
  So I don't have to do it myself

  Scenario: App just runs
    When I get help for "#{project_name}"
    Then the exit status should be 0
EOS
        end
        File.open(File.join(features_dir,"step_definitions","#{project_name}_steps.rb"),'w') do |file|
          file.puts <<EOS
When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `\#{app_name} help`)
end

# Add more step definitions here
EOS
        end
        File.open(File.join(features_dir,"support","env.rb"),'w') do |file|
          file.puts <<EOS
require 'aruba/cucumber'

ENV['PATH'] = "\#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}\#{File::PATH_SEPARATOR}\#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end
EOS
        end
        puts "Created #{features_dir}"
      end
    end

    def self.mk_binfile(root_dir,create_ext_dir,force,dry_run,project_name,commands)
      bin_file = File.join(root_dir,project_name,'bin',project_name)
      if !File.exist?(bin_file) || force
        if !dry_run
          File.open(bin_file,'w') do |file|
            file.chmod(0755)
            file.puts '#!/usr/bin/env ruby'
            file.puts <<EOS
require 'gli'
begin # XXX: Remove this begin/rescue before distributing your app
require '#{project_name}'
rescue LoadError
  STDERR.puts "In development, you need to use `bundle exec bin/#{project_name}` to run your app"
  STDERR.puts "At install-time, RubyGems will make sure lib, etc. are in the load path"
  STDERR.puts "Feel free to remove this message from bin/#{project_name} now"
  exit 64
end

class App
  extend GLI::App

  program_desc 'Describe your application here'

  version #{project_name_as_module_name(project_name)}::VERSION

  subcommand_option_handling :normal
  arguments :strict

  desc 'Describe some switch here'
  switch [:s,:switch]

  desc 'Describe some flag here'
  default_value 'the default'
  arg_name 'The name of the argument'
  flag [:f,:flagname]
EOS
            first = true
            commands.each do |command|
              file.puts <<EOS

  desc 'Describe #{command} here'
  arg_name 'Describe arguments to #{command} here'
EOS
              if first
                file.puts <<EOS
  command :#{command} do |c|
    c.desc 'Describe a switch to #{command}'
    c.switch :s

    c.desc 'Describe a flag to #{command}'
    c.default_value 'default'
    c.flag :f
    c.action do |global_options,options,args|

      # Your command logic here

      # If you have any errors, just raise them
      # raise "that command made no sense"

      puts "#{command} command ran"
    end
  end
EOS
              else
                file.puts <<EOS
  command :#{command} do |c|
    c.action do |global_options,options,args|
      puts "#{command} command ran"
    end
  end
EOS
              end
              first = false
            end
            file.puts <<EOS

  pre do |global,command,options,args|
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    true
  end

  post do |global,command,options,args|
    # Post logic here
    # Use skips_post before a command to skip this
    # block on that command only
  end

  on_error do |exception|
    # Error logic here
    # return false to skip default error handling
    true
  end
end

exit App.run(ARGV)
EOS
            puts "Created #{bin_file}"
          end
        end
      else
        puts bin_file + " exists; use --force to override"
        return false
      end
      true
    end

    def self.mkdirs(dirs,force,dry_run)
      exists = false
      if !force
        dirs.each do |dir|
          if File.exist? dir
            raise "#{dir} exists; use --force to override"
            exists = true
          end
        end
      end
      if !exists
        dirs.each do |dir|
          puts "Creating dir #{dir}..."
          if dry_run
            puts "dry-run; #{dir} not created"
          else
            FileUtils.mkdir_p dir
          end
        end
      else
        puts "Exiting..."
        return false
      end
      true
    end

  end
end
end
