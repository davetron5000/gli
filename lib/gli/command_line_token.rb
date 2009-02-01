module GLI
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

    # Returns the aliases for this as a string
    # for human readability
    def aliases_s
      !aliases || aliases.length == 0 ? '' : ("(" + aliases.join(',') + ")")
    end

    def name_for_usage
      name.to_s
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
end
