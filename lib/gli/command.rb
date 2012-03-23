require 'gli/command_line_token.rb'
require 'gli/copy_options_to_aliases.rb'
require 'gli/dsl.rb'

module GLI
  # A command to be run, in context of global flags and switches.  You are given an instance of this class
  # to the block you use for GLI#command.  You then use the methods described here to describe the 
  # command-specific command-line arguments, much as you use the methods in GLI to describe the global
  # command-line interface
  class Command < CommandLineToken
    include CopyOptionsToAliases
    include DSL

    # The parent of this command, either the GLI app, or another command
    attr_accessor :parent

    def context_description
      "in the command #{name}"
    end

    # Return true to avoid including this command in your help strings
    def nodoc
      false
    end

    # Create a new command
    #
    # +names+:: A String, Symbol, or Array of String or Symbol that represents the name(s) of this command.
    # +description+:: short description of this command as a Strign
    # +arguments_name+:: description of the arguments as a String, or nil if this command doesn't take arguments
    # +long_desc+:: a longer description of the command, possibly with multiple lines and text formatting
    # +skips_pre+:: if true, this command advertises that it doesn't want the pre block called first
    # +skips_post+:: if true, this command advertises that it doesn't want the post block called after it
    def initialize(names,description,arguments_name=nil,long_desc=nil,skips_pre=false,skips_post=false) # :nodoc:
      super(names,description,long_desc)
      @arguments_description = arguments_name || ''
      @skips_pre = skips_pre
      @skips_post = skips_post
      clear_nexts
    end

    # Return the arguments description
    def arguments_description #:nodoc:
      @arguments_description
    end

    # If true, this command doesn't want the pre block run before it executes
    def skips_pre #:nodoc:
      @skips_pre
    end

    # If true, this command doesn't want the post block run before it executes
    def skips_post #:nodoc:
      @skips_post
    end

    # Return the Array of the command's names
    def names #:nodoc:
      all_forms
    end

    def flag(*names)
      f = if parent.kind_of? Command
            parent.flag(*names)
          else
            super(*names)
          end
      f.associated_command = self
      f
    end

    def switch(*names)
      s = if parent.kind_of? Command
            parent.switch(*names)
          else
            super(*names)
          end
      s.associated_command = self
      s
    end

    def desc(d)
      if parent.kind_of? Command
        parent.desc(d)
      else
        super(d)
      end
    end

    def long_desc(d)
      if parent.kind_of? Command
        parent.long_desc(d)
      else
        super(d)
      end
    end

    def arg_name(d)
      if parent.kind_of? Command
        parent.arg_name(d)
      else
        super(d)
      end
    end

    def default_value(d)
      if parent.kind_of? Command
        parent.default_value(d)
      else
        super(d)
      end
    end

    # Get the usage string
    # CR: This should probably not be here
    def usage #:nodoc:
      usage = name.to_s
      usage += ' [command options]' if !flags.empty? || !switches.empty?
      usage += ' ' + @arguments_description if @arguments_description
      usage
    end

    # Return the flags as a Hash
    def flags #:nodoc:
      @flags ||= {}
    end
    # Return the switches as a Hash
    def switches #:nodoc:
      @switches ||= {}
    end

    def commands # :nodoc:
      @commands ||= {}
    end

    # Define the action to take when the user executes this command
    #
    # +block+:: A block of code to execute.  The block will be given 3 arguments:
    #           +global_options+:: A Hash (or Options, see GLI#use_openstruct) of the _global_ options specified
    #                              by the user, with defaults set and config file values used (if using a config file, see
    #                              GLI#config_file)
    #           +options+:: A Hash (or Options, see GLI#use_openstruct) of the command-specific options specified by the 
    #                       user, with defaults set and config file values used (if using a config file, see GLI#config_file)
    #           +arguments+:: An Array of Strings representing the unparsed command line arguments
    #           The block's result value is not used; raise an exception or use GLI#exit_now! if you need an early exit based
    #           on an error condition
    def action(&block)
      @action = block
    end

    def negatable?
      false
    end

    def self.name_as_string(name,negatable=false) #:nodoc:
      name.to_s
    end

    # Executes the command
    def execute(global_options,options,arguments) #:nodoc:
      subcommand = find_subcommand(arguments)
      if subcommand
        subcommand.execute(global_options,options,arguments[1..-1])
      else
        get_action(arguments).call(global_options,options,arguments)
      end
    end

    private

    def get_action(arguments)
      return @action if @action
      if parent.kind_of?(Command)
        if arguments.size > 0
          lambda do |global_options,options,arguments|
            raise UnknownCommand,"Unknown command '#{arguments[0]}'"
          end
        else
          lambda do |global_options,options,arguments|
            raise BadCommandLine,"Command '#{name}' requires a subcommand"
          end
        end
      else
        lambda do |global_options,options,arguments|
          raise "Command '#{name}' has no action block"
        end
      end
    end

    def find_subcommand(arguments)
      arguments = Array(arguments)
      return false if arguments.empty?
      subcommand = arguments.first
      self.commands.values.find do |command|
        [command.name,Array(command.aliases)].flatten.map(&:to_s).any? { |_| _ == subcommand }
      end
    end
  end
end
