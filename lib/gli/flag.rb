require 'gli/command_line_token.rb'

module GLI
  # Defines a flag, which is to say a switch that takes an argument
  class Flag < Switch

    attr_reader :default_value

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

    def usage(padding=0,long=false)
      printf_string = "    %-#{padding}s"
      string = ""
      if aliases
        aliases.each do |a|
          string += sprintf("#{printf_string}\n",name_for_usage(a))
        end
      end
      string += sprintf("#{printf_string} - %s (default %s)\n", name_for_usage,description,@default_value)
      return string
    end

    def name_for_usage(arg=name)
      string = arg.to_s
      (string.length == 1 ? "-#{string} " : "--#{string}=") + @argument_name
    end
  end
end
