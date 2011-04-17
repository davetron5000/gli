require 'gli/command_line_token.rb'
require 'gli/copy_options_to_aliases.rb'

module GLI
  # A command to be run, in context of global flags and switches.  You are given an instance of this class
  # to the block you use for GLI#command.  You then use the methods described here to describe the 
  # command-specific command-line arguments, much as you use the methods in GLI to describe the global
  # command-line interface
  class Command < CommandLineToken
    include CopyOptionsToAliases

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

    # describe the next switch or flag just as GLI#desc does.
    def desc(description); @next_desc = description; end
    # set the long description of this flag/switch, just as GLI#long_desc does.
    def long_desc(long_desc); @next_long_desc = long_desc; end
    # describe the argument name of the next flag, just as GLI#arg_name does.
    def arg_name(name); @next_arg_name = name; end
    # set the default value of the next flag, just as GLI#default_value does.
    def default_value(val); @next_default_value = val; end

    # Create a command-specific flag, similar to GLI#flag
    def flag(*names)
      names = [names].flatten
      GLI.verify_unused(names,flags,switches,"in command #{name}")
      flag = Flag.new(names,@next_desc,@next_arg_name,@next_default_value,@next_long_desc)
      flags[flag.name] = flag
      clear_nexts
    end

    # Create a command-specific switch, similar to GLI#switch
    def switch(*names)
      names = [names].flatten
      GLI.verify_unused(names,flags,switches,"in command #{name}")
      switch = Switch.new(names,@next_desc,@next_long_desc)
      switches[switch.name] = switch
      clear_nexts
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

    def self.name_as_string(name) #:nodoc:
      name.to_s
    end

    def clear_nexts #:nodoc:
      @next_desc = nil
      @next_arg_name = nil
      @next_default_value = nil
      @next_long_desc = nil
    end

    # Executes the command
    def execute(global_options,options,arguments) #:nodoc:
      @action.call(global_options,options,arguments)
    end
  end
end
