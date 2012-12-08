module GLI
  # Internals for make App work
  module AppSupport
    # Override the device of stderr; exposed only for testing
    def error_device=(e) #:nodoc:
      @stderr = e
    end

    def context_description
      "in global context"
    end

    # Reset the GLI module internal data structures; mostly useful for testing
    def reset # :nodoc:
      switches.clear
      flags.clear
      @commands = nil
      @commands_declaration_order = []
      @flags_declaration_order = []
      @switches_declaration_order = []
      @version = nil
      @config_file = nil
      @use_openstruct = false
      @prog_desc = nil
      @error_block = false
      @pre_block = false
      @post_block = false
      @default_command = :help
      @around_block = nil
      clear_nexts
    end

    # Get an array of commands, ordered by when they were declared
    def commands_declaration_order # :nodoc:
      @commands_declaration_order
    end

    # Get the version string
    def version_string #:nodoc:
      @version
    end

    # Get the default command for the entire app
    def get_default_command
      @default_command
    end

    # Runs whatever command is needed based on the arguments.
    #
    # +args+:: the command line ARGV array
    #
    # Returns a number that would be a reasonable exit code
    def run(args) #:nodoc:
      args = args.dup if @preserve_argv
      command = nil
      begin
        override_defaults_based_on_config(parse_config)

        add_help_switch_if_needed(switches)

        global_options,command,options,arguments = GLIOptionParser.new(commands,flags,switches,accepts,@default_command).parse_options(args)

        copy_options_to_aliased_versions(global_options,command,options)

        global_options = convert_to_openstruct_if_needed(global_options)
        options        = convert_to_openstruct_if_needed(options)

        if proceed?(global_options,command,options,arguments)
          call_command(command,global_options,options,arguments)
        end
        0
      rescue Exception => ex
        handle_exception(ex,command)
      end
    end


    # Return the name of the config file; mostly useful for generating help docs
    def config_file_name #:nodoc:
      @config_file
    end

    def accepts #:nodoc:
      @accepts ||= {}
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

    def clear_nexts # :nodoc:
      super
      @skips_post = false
      @skips_pre = false
      @skips_around = false
    end

    def stderr
      @stderr ||= STDERR
    end

    def self.included(klass)
      @stderr = $stderr
    end

    def flags # :nodoc:
      @flags ||= {}
    end

    def switches # :nodoc:
      @switches ||= {}
    end

    def commands # :nodoc:
      if !@commands
        @commands = { :help => GLI::Commands::Help.new(self), :_doc => GLI::Commands::Doc.new(self) }
        @commands_declaration_order ||= []
        @commands_declaration_order << @commands[:help]
        @commands_declaration_order << @commands[:_doc]
      end
      @commands
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

    def around_blocks
      @around_blocks || []
    end

    def help_sort_type
      @help_sort_type || :alpha
    end

    def help_text_wrap_type
      @help_text_wrap_type || :to_terminal
    end

    # Sets the default values for flags based on the configuration
    def override_defaults_based_on_config(config)
      override_default(flags,config)
      override_default(switches,config)

      override_command_defaults(commands,config)
    end

    def override_command_defaults(command_list,config)
      command_list.each do |command_name,command|
        next if command_name == :initconfig || command.nil?
        command_config = (config['commands'] || {})[command_name] || {}

        override_default(command.topmost_ancestor.flags,command_config)
        override_default(command.topmost_ancestor.switches,command_config)

        override_command_defaults(command.commands,command_config)
      end
    end

    def override_default(tokens,config)
      tokens.each do |name,token|
        token.default_value=config[name] if config[name]
      end
    end

  private

    def handle_exception(ex,command)
      if regular_error_handling?(ex)
        output_error_message(ex)
        if ex.kind_of?(OptionParser::ParseError) || ex.kind_of?(BadCommandLine)
          commands[:help] and commands[:help].execute({},{},command.nil? ? [] : [command.name.to_s])
        end
      end

      raise ex if ENV['GLI_DEBUG'] == 'true'

      ex.extend(GLI::StandardException)
      ex.exit_code
    end

    def output_error_message(ex)
      stderr.puts error_message(ex) unless no_message_given?(ex)
      if ex.kind_of?(OptionParser::ParseError) || ex.kind_of?(BadCommandLine)
        stderr.puts unless no_message_given?(ex)
      end
    end

    def no_message_given?(ex)
      ex.message == ex.class.name
    end

    # Possibly returns a copy of the passed-in Hash as an instance of GLI::Option.
    # By default, it will *not*. However by putting <tt>use_openstruct true</tt>
    # in your CLI definition, it will
    def convert_to_openstruct_if_needed(options) # :nodoc:
      @use_openstruct ? Options.new(options) : options
    end

    def add_help_switch_if_needed(switches)
      help_switch_exists = switches.values.find { |switch| 
        (Array(switch.aliases) + [switch.name]).find { |an_alias| 
          an_alias.to_s == 'help' 
        } 
      }
      unless help_switch_exists
        desc 'Show this message'
        switch :help, :negatable => false
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
      "error: #{ex.message}"
    end

    def call_command(command,global_options,options,arguments)
      arguments = arguments.map { |arg| arg.dup } # unfreeze
      code = lambda { command.execute(global_options,options,arguments) }
      nested_arounds = unless command.skips_around
                         around_blocks.inject do |outer_around, inner_around|
                           lambda { |go,c,o,a, code1|
                             inner = lambda { inner_around.call(go,c,o,a, code1) }
                             outer_around.call(go,c,o,a, inner)
                           }
                         end
                       end

      if nested_arounds
        nested_arounds.call(global_options,command, options, arguments, code)
      else
        code.call
      end

      unless command.skips_post
        post_block.call(global_options,command,options,arguments)
      end
    end

  end
end
