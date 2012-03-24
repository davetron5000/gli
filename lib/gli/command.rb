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
    include CommandSupport

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

    # Set the default command if this command has subcommands and the user doesn't 
    # provide a subcommand when invoking THIS command.  When nil, this will show an error and the help
    # for this command; when set, the command with this name will be executed.
    #
    # +command_name+:: The primary name of the subcommand of this command that should be run by default.
    def default_command(command_name)
      @default_command = command_name
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

    def self.name_as_string(name,negatable=false) #:nodoc:
      name.to_s
    end
  end
end
