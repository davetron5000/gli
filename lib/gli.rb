module GLI
  extend self

  @@next_desc = nil
  @@next_arg_name = nil
  @@next_default_value = nil

  # describe the next switch, flag, or command
  def desc(description)
    @@next_desc = description
  end

  # describe the argument name of the next flag
  def arg_name(name)
    @@next_arg_name = name
  end

  # set the default value of the next flag
  def default_value(val)
    @@next_default_value = val
  end

  # Create a flag, which is a switch that takes an argument
  def flag(names)
    flag = Flag.new(names,@@next_desc,@@next_arg_name,@@next_default_value)
    flages[flag.name] = flag
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  # Create a switch
  def switch(names)
    switch = Switch.new(names,@@next_desc)
    switchs[switch.name] = switch
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  def flages; @@flages ||= {}; end
  def switchs; @@switchs ||= {}; end

  # Defines a command line switch
  class Switch
    attr_reader :name
    attr_reader :aliases
    attr_reader :description

    def initialize(names,description)
      @description = description
      @names = Hash.new
      if names.is_a? Array
        names.each { |n| @names[Switch.as_switch(n)] = true }
        @name = names.shift
        @aliases = names.length > 0 ? names : nil
      else
        @name = names
        @names[Switch.as_switch(@name)] = true
        @aliases = nil
      end
    end

    def usage
      "#{Switch.as_switch(name)} - #{description}"
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

    # Returns the string as a command line switch
    def self.as_switch(symbol)
      string = symbol.to_s
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
      "#{Switch.as_switch(name)} #{@argument_name} - #{description} (default #{@default_value})"
    end
  end
end
