module GLI
  extend self

  @@next_desc = nil
  @@next_arg_name = nil
  @@next_default_value = nil

  def desc(description)
    @@next_desc = description
  end

  def arg_name(name)
    @@next_arg_name = name
  end

  def default_value(val)
    @@next_default_value = val
  end

  def switch(names)
    switch = Switch.new(names,@@next_desc,@@next_arg_name,@@next_default_value)
    switches[switch.name] = switch
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  def flag(names)
    flag = Flag.new(names,@@next_desc)
    flags[flag.name] = flag
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  def switches; @@switches ||= {}; end
  def flags; @@flags ||= {}; end

  # Defines a command line flag
  class Flag
    attr_reader :name
    attr_reader :aliases
    attr_reader :description

    def initialize(names,description)
      @description = description
      @names = Hash.new
      if names.is_a? Array
        names.each { |n| @names[Flag.as_flag(n)] = true }
        @name = names.shift
        @aliases = names.length > 0 ? names : nil
      else
        @name = names
        @names[Flag.as_flag(@name)] = true
        @aliases = nil
      end
    end

    def usage
      "#{Flag.as_flag(name)} - #{description}"
    end

    # Given the argument list, scans it looking for this flag
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

    # Returns the string as a command line flag
    def self.as_flag(symbol)
      string = symbol.to_s
      string.length == 1 ? "-#{string}" : "--#{string}"
    end
  end

  # Defines a switch, which is to say a flag that takes an argument
  class Switch < Flag

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
      "#{Flag.as_flag(name)} #{@argument_name} - #{description} (default #{@default_value})"
    end
  end
end
