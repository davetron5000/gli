require 'gli/command_line_token.rb'

module GLI
  # Defines a command line switch
  class Switch < CommandLineToken #:nodoc:

    attr_accessor :default_value

    # Creates a new switch
    #
    # names - Array of symbols or strings representing the names of this switch
    # options - hash of options:
    #           :desc - the short description
    #           :long_desc - the long description
    def initialize(names,options = {})
      super(names,options[:desc],options[:long_desc])
      @default_value = false
    end

    def self.name_as_string(name)
      string = name.to_s
      string.length == 1 ? "-#{string}" : "--[no-]#{string}"
    end
  end
end
