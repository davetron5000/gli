module GLI

  # Mixin that both GLI and Command can use to copy command-line options to the aliased versions
  # of flags and switches
  #
  # includers must provide the methods +flags+ and +switches+ that return an Array of Flag or Switch, 
  # respectively
  module CopyOptionsToAliases # :nodoc:
    # For each option in options, copies its value to keys for the aliases of the flags or
    # switches in gli_like
    #
    # options - Hash of options parsed from command line; this is an I/O param
    def copy_options_to_aliases(options) # :nodoc:
      new_options = {}
      options.each do |key,value|
        if flags[key] && flags[key].aliases
          copy_aliases(flags[key].aliases,new_options,value)
        elsif switches[key] && switches[key].aliases
          copy_aliases(switches[key].aliases,new_options,value)
        end
      end
      options.merge!(new_options)
    end

    private 

    def copy_aliases(aliases,new_options,value)
      aliases.each do |alias_name|
        new_options[alias_name] = value
      end
    end
  end
end
