require 'gli/command_line_token.rb'
require 'gli/switch.rb'

module GLI
  # Defines a flag, which is to say a switch that takes an argument
  class Flag < Switch # :nodoc:

    attr_accessor :default_value

    def initialize(names,description,argument_name=nil,default=nil,long_desc=nil)
      super(names,description,long_desc)
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
              raise BadCommandLine.new("#{matched} requires an argument")
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
        raise BadCommandLine.new("#{arg} requires an argument via #{arg}=argument")
      end
      @names.keys.each() do |name|
        match_string = "^#{name}=(.*)$"
        match_data = arg.match(match_string)
        return [true,name,$1] if match_data;
      end
      [false,nil,nil]
    end

    # Returns a string of all possible forms
    # of this flag.  Mostly intended for printing
    # to the user.
    def all_forms(joiner=', ')
      forms = all_forms_a
      string = forms.join(joiner)
      if forms[-1] =~ /^\-\-/
        string += '='
      else
        string += ' '
      end
      string += @argument_name
      return string
    end
  end
end
