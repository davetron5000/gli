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
      end
    end

    def self.mk_binfile(root_dir,create_ext_dir,force,dry_run,project_name,commands)
      bin_file = File.join(root_dir,project_name,'bin',project_name)
      if !File.exist?(bin_file) || force
        if !dry_run
          File.open(bin_file,'w') do |file|
            file.puts '#!/usr/bin/ruby'
            file.puts '$: << File.expand_path(File.dirname(__FILE__) + \'/../lib\')'
            file.puts '$: << File.expand_path(File.dirname(__FILE__) + \'/../ext\')' if create_ext_dir
            file.puts <<EOS
require 'gli'

include GLI

desc 'Describe some switch here'
switch [:s,:switch]

desc 'Describe some flag here'
default_value 'the default'
arg_name 'The name of the argument'
flag [:f,:flagname]
EOS
            commands.each do |command|
              file.puts <<EOS

desc 'Describe #{command} here'
arg_name 'Describe arguments to #{command} here'
command :#{command} do |c|
  c.desc 'Describe a switch to #{command}'
  c.switch :s

  c.desc 'Describe a flag to #{command}'
  c.default_value 'default'
  c.flag :s

  c.action do |global_options,options,args|
    # Your command logic here
  end
end
EOS
            end
            puts "Create #{bin_file}"
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
