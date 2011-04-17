require 'gli/command_line_token.rb'

module GLI
  # Defines a command line switch
  class Switch < CommandLineToken #:nodoc:

    def initialize(names,description,long_desc=nil)
      super(names,description,long_desc)
      @default_value = false
    end

    # Given the argument list, scans it looking for this switch
    # returning true if it's in the argumennt list (and removing it from the argument list)
    def get_value!(args)
      idx = -1
      args.each_index do |index|
        result = find_me(args[index])
        if result[0]
          if result[1]
            args[index] = result[1]
          else
            args.delete_at index
          end
          return result[0]
        end
      end
      @default_value
    end

    # Used only to configure what's returned if we do not detect this switch on the command line
    # This allows the configuration file to set a switch as always on
    def default_value=(default)
      @default_value = default
    end

    # Finds the switch in the given arg, returning the arg to keep.
    # Returns an array of size 2:
    # index 0:: true or false if the arg was found
    # index 1:: the remaining arg to keep in the command line or nil to remove it
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
end
