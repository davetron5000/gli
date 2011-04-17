module GLI
  # Abstract base class for a logical element of a command line, mostly so that subclasses can have similar
  # initialization and interface
  class CommandLineToken
    attr_reader :name #:ndoc:
    attr_reader :aliases #:ndoc:
    attr_reader :description #:ndoc:
    attr_reader :long_description #:ndoc:

    def initialize(names,description,long_description=nil) #:ndoc:
      @description = description
      @long_description = long_description
      @name,@aliases,@names = parse_names(names)
    end

    def usage #:nodoc:
      all_forms
    end

    # Sort based on name
    def <=>(other)
      self.name.to_s <=> other.name.to_s
    end

    private
    # Returns a string of all possible forms
    # of this flag.  Mostly intended for printing
    # to the user.
    def all_forms(joiner=', ')
      forms = all_forms_a
      forms.join(joiner)
    end


    # Handles dealing with the "names" param, parsing
    # it into the primary name and aliases list
    def parse_names(names)
      # Allow strings; convert to symbols
      names = [names].flatten.map { |name| name.to_sym } 
      names_hash = Hash.new
      names.each do |name| 
        raise ArgumentError.new("#{name} has spaces; they are not allowed") if name.to_s =~ /\s/
        names_hash[self.class.name_as_string(name)] = true
      end
      name = names.shift
      aliases = names.length > 0 ? names : nil
      [name,aliases,names_hash]
    end

    def all_forms_a
      forms = [self.class.name_as_string(name)]
      if aliases
        forms |= aliases.collect { |one_alias| self.class.name_as_string(one_alias) }.sort { |one,two| two.length <=> one.length }
      end
      forms
    end
  end
end
