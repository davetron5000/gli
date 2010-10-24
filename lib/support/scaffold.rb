require 'gli'
require 'fileutils'

module GLI
  class Scaffold

    def self.create_scaffold(root_dir,create_test_dir,create_ext_dir,project_name,commands,force=false,dry_run=false)
      dirs = [File.join(root_dir,project_name,'lib')]
      dirs << File.join(root_dir,project_name,'bin')
      dirs << File.join(root_dir,project_name,'test') if create_test_dir
      dirs << File.join(root_dir,project_name,'ext') if create_ext_dir

      if mkdirs(dirs,force,dry_run)
        mk_binfile(root_dir,create_ext_dir,force,dry_run,project_name,commands)
        mk_readme(root_dir,dry_run,project_name)
        mk_gemspec(root_dir,dry_run,project_name)
        mk_rakefile(root_dir,dry_run,project_name,create_test_dir)
      end
    end

    def self.mk_readme(root_dir,dry_run,project_name)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/README.rdoc",'w') do |file|
        file << "= #{project_name}\n\n"
        file << "Describe your project here\n\n"
        file << ":include:#{project_name}.rdoc\n\n"
      end
      File.open("#{root_dir}/#{project_name}/#{project_name}.rdoc",'w') do |file|
        file << "= #{project_name}\n\n"
        file << "Generate this with\n    #{project_name} rdoc\nAfter you have described your command line interface"
      end
    end

    def self.mk_gemspec(root_dir,dry_run,project_name)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/#{project_name}.gemspec",'w') do |file|
        file.puts <<EOS
spec = Gem::Specification.new do |s| 
  s.name = '#{project_name}'
  s.version = '0.0.01'
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files = %w(
bin/#{project_name}
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','#{project_name}.rdoc']
  s.rdoc_options << '--title' << 'Git Like Interface' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << '#{project_name}'
end
EOS
      end
    end

    def self.mk_rakefile(root_dir,dry_run,project_name,create_test_dir)
      return if dry_run
      File.open("#{root_dir}/#{project_name}/Rakefile",'w') do |file|
        file.puts <<EOS
require 'rake/clean'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('#{project_name}.gemspec'))

Rake::GemPackageTask.new(spec) do |pkg|
end

EOS
        if create_test_dir
          file.puts <<EOS
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
end

task :default => :test
EOS
          File.open("#{root_dir}/#{project_name}/test/tc_nothing.rb",'w') do |test_file|
            test_file.puts <<EOS
require 'test/unit'
require 'test/unit/ui/console/testrunner'

class TC_testNothing < Test::Unit::TestCase

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
        else
          file.puts "task :default => :package\n"
        end
      end
    end

    def self.mk_binfile(root_dir,create_ext_dir,force,dry_run,project_name,commands)
      bin_file = File.join(root_dir,project_name,'bin',project_name)
      if !File.exist?(bin_file) || force
        if !dry_run
          File.open(bin_file,'w') do |file|
            file.chmod(0755)
            file.puts '#!/usr/bin/ruby'
						file.puts "require 'support/compatibility'"
            file.puts '$: << File.expand_path(File.dirname(File.realpath(__FILE__)) + \'/../lib\')'
            file.puts '$: << File.expand_path(File.dirname(File.realpath(__FILE__)) + \'/../ext\')' if create_ext_dir
            file.puts <<EOS
require 'rubygems'
require 'gli'

include GLI

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
  c.flag :s
  c.action do |global_options,options,args|

    # Your command logic here
     
    # If you have any errors, just raise them
    # raise "that command made no sense"
  end
end
EOS
              else
                file.puts <<EOS
command :#{command} do |c|
  c.action do |global_options,options,args|
  end
end
EOS
              end
              first = false
            end
            file.puts <<EOS

pre do |global,command,options,args|
  # Pre logic here
  # Return true to proceed; false to abourt and not call the
  # chosen command
  true
end

post do |global,command,options,args|
  # Post logic here
end

on_error do |exception|
  # Error logic here
  # return false to skip default error handling
  true
end

GLI.run(ARGV)
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
            puts "#{dir} exists; use --force to override"
            exists = true
          end
        end
      end
      if !exists
        dirs.each do |dir|
          puts "Creating dir #{dir}..."
          if dry_run
            $stderr.puts "dry-run; #{dir} not created"
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
