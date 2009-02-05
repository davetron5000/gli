require 'gli/command_line_token.rb'

module GLI
  # A command to be run, in context of global flags and switches
  class Command < CommandLineToken

    # Create a new command
    #
    # [names] the name or names of this command (symbol or Array of symbols)
    # [description] description of this command
    # [arguments_name] description of the arguments, or nil if this command doesn't take arguments
    #
    def initialize(names,description,arguments_name=nil)
      super(names,description)
      @arguments_description = arguments_name || ''
      clear_nexts
    end

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
    # describe the argument name of the next flag
    def arg_name(name); @next_arg_name = name; end
    # set the default value of the next flag
    def default_value(val); @next_default_value = val; end

    def flag(names)
      flag = Flag.new(names,@next_desc,@next_arg_name,@next_default_value)
      flags[flag.name] = flag
      clear_nexts
    end

    # Create a switch
    def switch(names)
      switch = Switch.new(names,@next_desc)
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
    end

    def execute(global_options,options,arguments)
      @action.call(global_options,options,arguments)
    end
  end
end
