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
    def context_description
      "in global context"
    end

    # Override the device of stderr; exposed only for testing
    def error_device=(e) #:nodoc:
      @stderr = e
    end

    # Reset the GLI module internal data structures; mostly useful for testing
    def reset # :nodoc:
      switches.clear
      flags.clear
      commands.clear
      @version = nil
      @config_file = nil
      @use_openstruct = false
      @prog_desc = nil
      @error_block = false
      @pre_block = false
      @post_block = false
      clear_nexts

      desc 'Show this message'
      switch :help
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
        @config_file = File.join(File.expand_path('~'),filename)
      end
      commands[:initconfig] = InitConfig.new(@config_file,commands)
      @config_file
    end

    # Return the name of the config file; mostly useful for generating help docs
    def config_file_name #:nodoc:
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
    # object - the class (or whatever) that triggers the type conversion
    # block - the block that will be given the string argument and is expected
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

    def accepts #:nodoc:
      @accepts ||= {}
    end

    # Runs whatever command is needed based on the arguments. 
    #
    # +args+:: the command line ARGV array
    #
    # Returns a number that would be a reasonable exit code
    def run(args) #:nodoc:
      rdoc = RDocCommand.new(commands,program_name,program_desc,flags,switches)
      commands[:rdoc] ||= rdoc
      #commands[:help] ||= GLI::Commands::Help.new(self)#DefaultHelpCommand.new(@version,self,rdoc)
      begin
        override_defaults_based_on_config(parse_config)

        global_options,command,options,arguments = parse_options(args)

        copy_options_to_aliased_versions(global_options,command,options)

        global_options = convert_to_openstruct?(global_options)

        options = convert_to_openstruct?(options)
        if proceed?(global_options,command,options,arguments)
          command ||= commands[:help]
          command.execute(global_options,options,arguments)
          unless command.skips_post
            post_block.call(global_options,command,options,arguments)
          end
        end
        0
      rescue Exception => ex

        stderr.puts error_message(ex) if regular_error_handling?(ex)

        raise ex if ENV['GLI_DEBUG'] == 'true'

        ex.extend(GLI::StandardException)
        ex.exit_code
      end
    end

    # True if we should proceed with executing the command; this calls
    # the pre block if it's defined
    def proceed?(global_options,command,options,arguments) #:nodoc:
      if command && command.skips_pre
        true
      else
        pre_block.call(global_options,command,options,arguments) 
      end
    end

    # Returns true if we should proceed with GLI's basic error handling.
    # This calls the error block if the user provided one
    def regular_error_handling?(ex) #:nodoc:
      if @error_block
        @error_block.call(ex)
      else
        true
      end
    end

    # Returns a String of the error message to show the user
    # +ex+:: The exception we caught that launched the error handling routines
    def error_message(ex) #:nodoc:
      msg = "error: #{ex.message}"
      case ex
      when UnknownCommand
        msg += ". Use '#{program_name} help' for a list of commands"
      when UnknownCommandArgument
        msg += ". Use '#{program_name} help #{ex.command.name}' for a list of command options"
      when UnknownGlobalArgument
        msg += ". Use '#{program_name} help' for a list of global options"
      end
      msg
    end

    # Simpler means of exiting with a custom exit code.  This will 
    # raise a CustomExit with the given message and exit code, which will ultimatley
    # cause your application to exit with the given exit_code as its exit status
    def exit_now!(message,exit_code)
      raise CustomExit.new(message,exit_code)
    end

    # Set or get the name of the program, if you don't want the default (which is
    # the name of the command line program).  This
    # is only used currently in the help and rdoc commands.
    #
    # +override+:: A String that represents the name of the program to use, other than the default.
    #
    # Returns the current program name, as a String
    def program_name(override=nil)
      @program_name ||= $0.split(/\//)[-1]
      if override
        @program_name = override
      end
      @program_name
    end

    # Possibly returns a copy of the passed-in Hash as an instance of GLI::Option.
    # By default, it will *not*. However by putting <tt>use_openstruct true</tt>
    # in your CLI definition, it will
    def convert_to_openstruct?(options) # :nodoc:
      @use_openstruct ? Options.new(options) : options
    end

    # Copies all options in both global_options and options to keys for the aliases of those flags.
    # For example, if a flag works with either -f or --flag, this will copy the value from [:f] to [:flag]
    # to allow the user to access the options by any alias
    def copy_options_to_aliased_versions(global_options,command,options) # :nodoc:
      copy_options_to_aliases(global_options)
      command.copy_options_to_aliases(options)
    end

    def parse_config # :nodoc:
      config = {
        'commands' => {},
      }
      if @config_file && File.exist?(@config_file)
        require 'yaml'
        config.merge!(File.open(@config_file) { |file| YAML::load(file) })
      end
      config
    end

    # Given the command-line argument array, returns and array of size 4:
    #
    # 0:: global options
    # 1:: command, as a Command
    # 2:: command-specific options
    # 3:: unparsed arguments
    def parse_options(args) # :nodoc:
      args_clone = args.clone
      global_options = {}
      command = nil
      command_options = {}
      remaining_args = nil

      unless switches.values.find { |_| _.name.to_s == 'help' || Array(_.aliases).find { |an_alias| an_alias.to_s == 'help' } }
        desc 'Show this message'
        switch :help, :negatable => false
      end

      global_options,command_name,args = parse_global_options(args)
      flags.each { |name,flag| global_options[name] = flag.default_value unless global_options[name] }
      #g,c,o,a = old_parse_options(args_clone)

      command_name ||= 'help'
      command = find_command(command_name)
      raise UnknownCommand.new("Unknown command '#{command_name}'") unless command

        command_options,args = parse_command_options(command,args)
      command.flags.each { |name,flag| command_options[name] = flag.default_value unless command_options[name] }
      command.switches.each do |name,switch| 
        command_options[name] = switch.default_value unless command_options[name] 
      end

      [global_options,command,command_options,args]
    end

    # Get an OptionParser that will parse the given flags and switches
    def option_parser(flags,switches)
      options = {}
      option_parser = OptionParser.new do |opts|
        accepts.each { |object,block| opts.accept(object) { |_| block.call(_) } }
        [ switches, flags ].each do |tokens,string_maker|
          tokens.each do |_,token|
            opts.on(*token.arguments_for_option_parser) do |arg|
              token_names = [token.name,token.aliases].flatten.reject { |_| _.nil? }
              token_names.each do |name|
                token_names.each { |_| options[_] = arg }
              end
            end
          end
        end
      end
      [option_parser,options]
    end

    def parse_command_options(command,args)
      option_parser,command_options = option_parser(command.flags,command.switches)
      begin
        option_parser.parse!(args)
      rescue OptionParser::InvalidOption => ex
        raise UnknownCommandArgument.new("Unknown option #{ex.args.join(' ')}",command)
      rescue OptionParser::InvalidArgument => ex
        raise UnknownCommandArgument.new("#{ex.reason}: #{ex.args.join(' ')}",command)
      end
      [command_options,args]
    end

    def parse_global_options(args,&error_handler)
      if error_handler.nil?
        error_handler = lambda { |message|
          raise UnknownGlobalArgument.new(message)
        }
      end
      option_parser,global_options = option_parser(flags,switches)
      command = nil
      begin
        option_parser.order!(args) do |non_option|
          command = non_option
          break
        end
      rescue OptionParser::InvalidOption => ex
        error_handler.call("Unknown option #{ex.args.join(' ')}")
      rescue OptionParser::InvalidArgument => ex
        error_handler.call("#{ex.reason}: #{ex.args.join(' ')}")
      end
      [global_options,command,args]
    end

    def clear_nexts # :nodoc:
      super
      @skips_post = false
      @skips_pre = false
    end

    def self.included(klass)
      @stderr = $stderr
    end

    def stderr
      @stderr ||= STDERR
    end

    def flags # :nodoc:
      @flags ||= {}
    end
    def switches # :nodoc:
      @switches ||= {}
    end
    def commands # :nodoc:
      @commands ||= {:help => GLI::Commands::Help.new(self)}
    end

    def pre_block
      @pre_block ||= Proc.new do
        true
      end
    end

    def post_block
      @post_block ||= Proc.new do
      end
    end

    def find_command(name) # :nodoc:
      sym = name.to_sym
      return commands[name.to_sym] if commands[sym]
      commands.each do |command_name,command|
        return command if (command.aliases && command.aliases.include?(sym))
      end
      nil
    end

    # Sets the default values for flags based on the configuration
    def override_defaults_based_on_config(config)
      override_default(flags,config)
      override_default(switches,config)

      commands.each do |command_name,command|
        command_config = config['commands'][command_name] || {}

        override_default(command.flags,command_config)
        override_default(command.switches,command_config)
      end
    end

    def override_default(tokens,config)
      tokens.each do |name,token|
        token.default_value=config[name] if config[name]
      end
    end

  end
end
