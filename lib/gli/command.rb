require 'gli/command_line_token.rb'

module GLI
  # A command to be run, in context of global flags and switches
  class Command < CommandLineToken

    # Create a new command
    #
    # [names] the name or names of this command (symbol or Array of symbols)
    # [description] description of this command
    # [arguments_name] description of the arguments, or nil if this command doesn't take arguments
    # [long_desc] a longer description of the command, possibly with multiple lines and text formatting
    #
    def initialize(names,description,arguments_name=nil,long_desc=nil)
      super(names,description,long_desc)
      @arguments_description = arguments_name || ''
      clear_nexts
    end

    def arguments_description; @arguments_description; end

    def names
      all_forms
    end

    def usage
      usage = name.to_s
      usage += ' [options]' if !flags.empty? || !switches.empty?
      usage += ' ' + @arguments_description if @arguments_description
      usage
    end

    def flags; @flags ||= {}; end
    def switches; @switches ||= {}; end

    # describe the next switch or flag
    def desc(description); @next_desc = description; end
    # long description of this flag/switch
    def long_desc(long_desc); @next_long_desc = long_desc; end
    # describe the argument name of the next flag
    def arg_name(name); @next_arg_name = name; end
    # set the default value of the next flag
    def default_value(val); @next_default_value = val; end

    def flag(*names)
      names = [names].flatten
      GLI.verify_unused(names,flags,switches,"in command #{name}")
      flag = Flag.new(names,@next_desc,@next_arg_name,@next_default_value,@next_long_desc)
      flags[flag.name] = flag
      clear_nexts
    end

    # Create a switch
    def switch(*names)
      names = [names].flatten
      GLI.verify_unused(names,flags,switches,"in command #{name}")
      switch = Switch.new(names,@next_desc,@next_long_desc)
      switches[switch.name] = switch
      clear_nexts
    end

    def action(&block)
      @action = block
    end

    def self.name_as_string(name)
      name.to_s
    end

    def clear_nexts
      @next_desc = nil
      @next_arg_name = nil
      @next_default_value = nil
      @next_long_desc = nil
    end

    def execute(global_options,options,arguments)
      @action.call(global_options,options,arguments)
    end
  end
end
