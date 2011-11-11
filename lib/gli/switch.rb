require 'gli/command_line_option.rb'

module GLI
  # Defines a command line switch
  class Switch < CommandLineOption #:nodoc:

    attr_accessor :default_value

    # Creates a new switch
    #
    # names - Array of symbols or strings representing the names of this switch
    # options - hash of options:
    #           :desc - the short description
    #           :long_desc - the long description
    #           :negatable - true or false if this switch is negatable; defaults to true
    #           :default_value - ignored, switches default to false
    def initialize(names,options = {})
      super(names,options)
      @default_value = false
      @negatable = options[:negatable].nil? ? true : options[:negatable]
    end

    def arguments_for_option_parser
      all_forms_a
    end

    def negatable?
      @negatable
    end
  end
end
