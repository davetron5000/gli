require 'etc'
require 'optparse'
require 'gli/copy_options_to_aliases'
require 'gli/dsl'

module GLI
  # A means to define and parse a command line interface that works as
  # Git's does, in that you specify global options, a command name, command
  # specific options, and then command arguments.
  module App
    include CopyOptionsToAliases
    include DSL
    include AppSupport

    # Loads ruby files in the load path that start with 
    # +path+, which are presumed to be commands for your executable.
    # This is a glorified +require+, but could also be used as a plugin mechanism.
    # You could manipualte the load path at runtime and this call
    # would find those files
    #
    # path:: a path relative to somewhere in the <code>LOAD_PATH</code>, from which all <code>.rb</code> files will be required.
    def commands_from(path)
      $LOAD_PATH.each do |load_path|
        commands_path = File.join(load_path,path)
        if File.exists? commands_path
          Dir.entries(commands_path).each do |entry|
            file = File.join(commands_path,entry)
            if file =~ /\.rb$/
              require file
            end
          end
        end
      end
    end

    # Describe the overall application/programm.  This should be a one-sentence summary
    # of what your program does that will appear in the help output.
    #
    # +description+:: A String of the short description of your program's purpose
    def program_desc(description=nil) 
      if description
        @program_desc = description
      end
      @program_desc
    end

    # Use this if the following command should not have the pre block executed.
    # By default, the pre block is executed before each command and can result in
    # aborting the call.  Using this will avoid that behavior for the following command
    def skips_pre
      @skips_pre = true
    end

    # Use this if the following command should not have the post block executed.
    # By default, the post block is executed after each command.
    # Using this will avoid that behavior for the following command
    def skips_post
      @skips_post = true
    end

    # Sets that this app uses a config file as well as the name of the config file.  
    #
    # +filename+:: A String representing the path to the file to use for the config file.  If it's an absolute
    #              path, this is treated as the path to the file.  If it's *not*, it's treated as relative to the user's home
    #              directory as produced by <code>File.expand_path('~')</code>.
    def config_file(filename)
      if filename =~ /^\//
        @config_file = filename
      else
        @config_file = File.join(File.expand_path(ENV['HOME']),filename)
      end
      commands[:initconfig] = InitConfig.new(@config_file,commands,flags,switches)
      @config_file
    end

    # Define a block to run after command line arguments are parsed
    # but before any command is run.  If this block raises an exception
    # the command specified will not be executed.
    # The block will receive the global-options,command,options, and arguments
    # If this block evaluates to true, the program will proceed; otherwise
    # the program will end immediately
    def pre(&a_proc)
      @pre_block = a_proc
    end

    # Define a block to run after the command was executed, <b>only
    # if there was not an error</b>.
    # The block will receive the global-options,command,options, and arguments
    def post(&a_proc)
      @post_block = a_proc
    end

    # Define a block to run if an error occurs.
    # The block will receive any Exception that was caught.
    # It should evaluate to false to avoid the built-in error handling (which basically just
    # prints out a message). GLI uses a variety of exceptions that you can use to find out what 
    # errors might've occurred during command-line parsing:
    # * GLI::CustomExit
    # * GLI::UnknownCommandArgument
    # * GLI::UnknownGlobalArgument
    # * GLI::UnknownCommand
    # * GLI::BadCommandLine
    def on_error(&a_proc)
      @error_block = a_proc
    end

    # Indicate the version of your application
    #
    # +version+:: String containing the version of your application.  
    def version(version)
      @version = version
    end

    # Call this with +true+ will cause the +global_options+ and
    # +options+ passed to your code to be wrapped in
    # Options, which is a subclass of +OpenStruct+ that adds
    # <tt>[]</tt> and <tt>[]=</tt> methods.
    #
    # +use_openstruct+:: a Boolean indicating if we should use OpenStruct instead of Hashes
    def use_openstruct(use_openstruct)
      @use_openstruct = use_openstruct
    end

    # Configure a type conversion not already provided by the underlying OptionParser.
    # This works more or less like the OptionParser version.
    #
    # object:: the class (or whatever) that triggers the type conversion
    # block:: the block that will be given the string argument and is expected
    #         to return the converted value
    #
    # Example
    #
    #     accept(Hash) do |value|
    #       result = {}
    #       value.split(/,/) do |pair|
    #         k,v = pair.split(/:/)
    #         result[k] = v
    #       end
    #       result
    #     end
    #
    #     flag :properties, :type => Hash
    def accept(object,&block)
      accepts[object] = block
    end

    # Simpler means of exiting with a custom exit code.  This will 
    # raise a CustomExit with the given message and exit code, which will ultimatley
    # cause your application to exit with the given exit_code as its exit status
    # Use #help_now! if you want to show the help in addition to the error message
    #
    # message:: message to show the user
    # exit_code:: exit code to exit as, defaults to 1
    def exit_now!(message,exit_code=1)
      raise CustomExit.new(message,exit_code)
    end

    # Exit now, showing the user help for the command they executed.  Use #exit_now! to just show the error message
    #
    # message:: message to indicate how the user has messed up the CLI invocation
    def help_now!(message)
      exception = OptionParser::ParseError.new(message)
      class << exception
        def exit_code; 64; end
      end
      raise exception
    end

    def program_name(override=nil) #:nodoc:
      warn "#program_name has been deprecated"
    end

    # Sets a default command to run when none is specified on the command line.  Note that
    # if you use this, you won't be able to pass arguments, flags, or switches
    # to the command when run in default mode.  All flags and switches are treated
    # as global, and any argument will be interpretted as the command name and likely
    # fail.
    #
    # +command+:: Command as a Symbol to run as default
    def default_command(command)
      @default_command = command.to_sym
    end
  end
end
