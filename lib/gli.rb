module GLI
  extend self

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
    clear_nexts
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
        if @names[args[i]]
          idx = i
          break
        end
      end
      if idx > -1
        args.delete_at idx
        idx
      else
        false
      end
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
      idx = super(args)
      val = nil
      if idx
        val = args.delete_at idx
      end
      val || @default_value
    end

    def usage
      "#{Switch.name_as_string(name)} #{@argument_name} - #{description} (default #{@default_value})"
    end
  end
end
