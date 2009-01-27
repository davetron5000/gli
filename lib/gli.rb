module GLI
  extend self

  def reset
    switches.clear
    flags.clear
    commands.clear
    clear_nexts
  end

  # describe the next switch, flag, or command
  def desc(description); @@next_desc = description; end
  # describe the argument name of the next flag
  def arg_name(name); @@next_arg_name = name; end
  # set the default value of the next flag
  def default_value(val); @@next_default_value = val; end

  # Create a flag, which is a switch that takes an argument
  def flag(names)
    flag = Flag.new(names,@@next_desc,@@next_arg_name,@@next_default_value)
    flags[flag.name] = flag
    clear_nexts
  end

  # Create a switch
  def switch(names)
    switch = Switch.new(names,@@next_desc)
    switches[switch.name] = switch
    clear_nexts
  end

  def command(names)
    command = Command.new(names,@@next_desc)
    commands[command.name] = command
    yield command
    clear_nexts
  end

  def run(args)
  end

  # Returns an array of four values:
  #  * global options (as a Hash)
  #  * command name (as a String)
  #  * command options (as a Hash)
  #  * arguments (as an Array)
  def parse_options(args)
    return parse_options_helper(args.clone,Hash.new,nil,Hash.new,Array.new)
  end

  # Finds the index of the first non-flag
  # argument or -1 if there wasn't one.
  def find_non_flag_index(args)
    args.each_index do |i|
      return i if args[i] =~ /^[^\-]/;
      return i-1 if args[i] =~ /^\-\-$/;
    end
    -1;
  end

  alias :d :desc
  alias :f :flag
  alias :s :switch
  alias :c :command

  def clear_nexts
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  clear_nexts

  def flags; @@flags ||= {}; end
  def switches; @@switches ||= {}; end
  def commands; @@commands ||= {}; end

  # Recursive helper for parsing command line options
  # [args] the arguments that have yet to be processed
  # [global_options] the global options hash
  # [command] the Command that has been identified (or nil if not identified yet)
  # [command_options] options for Command
  # [arguments] the arguments for Command
  #
  # This works by finding the first non-switch/flag argument, and taking that sublist and trying to pick out
  # flags and switches.  After this is done, one of the following is true:
  #   * the sublist is empty - in this case, go again, as there might be more flags to parse
  #   * the sublist has a flag left in it - unknown flag; we bail
  #   * the sublist has a non-flag left in it - this is the command (or the start of the arguments list)
  #
  # This sort does the same thing in two phases; in the first phase, the command hasn't been identified, so
  # we are looking for global switches and flags, ending when we get the command.
  #
  # Once the command has been found, we start looking for command-specific flags and switches.
  # When those have been found, we know the rest of the argument list is arguments for the command
  def parse_options_helper(args,global_options,command,command_options,arguments)
    non_flag_i = find_non_flag_index(args)
    all_flags = false
    if non_flag_i == 0
      # no flags
      command_name = args.shift
      command = commands[command_name.to_sym]
      raise(UnknownCommandException,"Unknown command '#{command_name}'") if !command
      return parse_options_helper(args,global_options,command,command_options,arguments)
    elsif non_flag_i == -1
      all_flags = true
    end

    try_me = args[0..non_flag_i]
    rest = args[(non_flag_i+1)..args.length]
    if all_flags
      try_me = args 
      rest = []
    end

    # Suck up whatever options we can
    switch_hash = switches
    flag_hash = flags
    options = global_options
    if command
      switch_hash = command.switches
      flag_hash = command.flags
      options = command_options
    end

    switch_hash.each do |name,switch|
      value = switch.get_value!(try_me)
      options[name] = value if !options[name]
    end

    flag_hash.each do |name,flag|
      value = flag.get_value!(try_me)
      options[name] = value if !options[name]
    end

    if try_me.empty?
      return [global_options,command,command_options,arguments] if rest.empty?
      # If we have no more options we've parsed them all
      # and rest may have more
      return parse_options_helper(rest,global_options,command,command_options,arguments)
    else
      if command
        check = rest
        check = rest | try_me if all_flags 
        check.each() do |arg| 
          if arg =~ /^\-\-$/
            try_me.delete arg
            break 
          end
          raise(UnknownArgumentException,"Unknown argument #{arg}") if arg =~ /^\-/ 
        end
        return [global_options,command,command_options,try_me | rest]
      else
        # Now we have our command name
        command_name = try_me.shift
        raise(UnknownArgumentException,"Unknown argument #{command_name}") if command_name =~ /^\-/

        command = commands[command_name.to_sym]
        raise(UnknownCommandException,"Unknown command '#{command_name}'") if !command

        return parse_options_helper(rest,global_options,command,command_options,arguments)
      end
    end

  end


  # Logical element of a command line, mostly so that subclasses can have similar
  # initialization and interface
  class CommandLineToken
    attr_reader :name
    attr_reader :aliases
    attr_reader :description

    def initialize(names,description)
      @description = description
      @name,@aliases,@names = parse_names(names)
    end

    private 

    def parse_names(names)
      names_hash = Hash.new
      names = names.is_a?(Array) ? names : [names]
      names.each { |n| names_hash[self.class.name_as_string(n)] = true }
      name = names.shift
      aliases = names.length > 0 ? names : nil
      [name,aliases,names_hash]
    end
  end

  # A command to be run, in context of global flags and switches
  class Command < CommandLineToken
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

    def action
    end

    # Returns a multi-line usage statement for this command
    def usage
      string = "#{name} - #{description}\n"
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
  end


  # Defines a command line switch
  class Switch < CommandLineToken

    def initialize(names,description)
      super(names,description)
    end

    def usage
      "#{Switch.name_as_string(name)} - #{description}"
    end

    # Given the argument list, scans it looking for this switch
    # returning true if it's in the argumennt list (and removing it from the argument list)
    def get_value!(args)
      idx = -1
      args.each_index do |i|
        result = find_me(args[i])
        if result[0]
          if result[1]
            args[i] = result[1]
          else
            args.delete_at i
          end
          return result[0]
        end
      end
      false
    end

    # Finds the switch in the given arg, returning the arg to keep.
    # Returns an array of size 2:
    # [0] true or false if the arg was found
    # [1] the remaining arg to keep in the command line or nil to remove it
    def find_me(arg)
      if @names[arg]
        return [true,nil]
      end
      @names.keys.each() do |name|
        if name =~ /^-(\w)$/
          match_string = "^\\-(\\w*)#{$1}(\\w*)$"
          match_data = arg.match(match_string)
          if match_data
            # Note that if [1] and [2] were both empty 
            # we'd have returned above
            return [true, "-" + match_data[1] + match_data[2]]
          end
        end
      end
      [false]
    end

    def self.name_as_string(name)
      string = name.to_s
      string.length == 1 ? "-#{string}" : "--#{string}"
    end
  end

  # Defines a flag, which is to say a switch that takes an argument
  class Flag < Switch

    def initialize(names,description,argument_name=nil,default=nil)
      super(names,description)
      @argument_name = argument_name || "arg"
      @default_value = default
    end

    def get_value!(args)
      args.each_index() do |index|
        arg = args[index]
        present,matched,value = find_me(arg)
        if present
          args.delete_at index
          if !value || value == ''
            if args[index]
              value = args[index]
              args.delete_at index
              return value
            else
              raise(MissingArgumentException,"#{matched} requires an argument")
            end
          else
            return value
          end
        end
      end
      return @default_value
    end

    def find_me(arg)
      if @names[arg]
        return [true,arg,nil] if arg.length == 2
        # This means we matched the long-form, but there's no argument
        raise(MissingArgumentException,"#{arg} requires an argument via #{arg}=argument")
      end
      @names.keys.each() do |name|
        match_string = "^#{name}=(.*)$"
        match_data = arg.match(match_string)
        return [true,name,$1] if match_data;
      end
      [false,nil,nil]
    end

    def usage
      "#{Switch.name_as_string(name)} #{@argument_name} - #{description} (default #{@default_value})"
    end
  end

  class UnknownArgumentException < Exception
  end

  class UnknownCommandException < Exception
  end

  class MissingArgumentException < Exception
  end
end
