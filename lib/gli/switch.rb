require 'gli/command_line_token.rb'

module GLI
  # Defines a command line switch
  class Switch < CommandLineToken #:nodoc:

    attr_accessor :default_value

    def initialize(names,description,long_desc=nil)
      super(names,description,long_desc)
      @default_value = false
    end

    def self.name_as_string(name)
      string = name.to_s
      string.length == 1 ? "-#{string}" : "--[no-]#{string}"
    end
  end
end
