require 'gli/command_line_token.rb'

module GLI
  # A command to be run, in context of global flags and switches
  class Command < CommandLineToken

    attr_writer :action

    def initialize(names,description)
      super(names,description)
      clear_nexts
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

    # Returns a multi-line usage statement for this command
    def usage(padding=0,long=true)
      string = sprintf("%#{padding}s - %s\n",name,description)
      return string if !long
      flags.keys.each { |flag| string += "    #{flags[flag].usage}\n" }
      switches.keys.each { |switch| string += "    #{switches[switch].usage}\n" }
      string
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
