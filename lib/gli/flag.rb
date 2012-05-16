require 'gli/command_line_option.rb'

module GLI
  # Defines a flag, which is to say a switch that takes an argument
  class Flag < CommandLineOption # :nodoc:

    # Regexp that is used to see if the flag's argument matches
    attr_reader :must_match

    # Type to which we want to cast the values
    attr_reader :type

    # Name of the argument that user configured
    attr_reader :argument_name

    # Creates a new option
    #
    # names - Array of symbols or strings representing the names of this switch
    # options - hash of options:
    #           :desc - the short description
    #           :long_desc - the long description
    #           :default_value - the default value of this option
    #           :arg_name - the name of the flag's argument, default is "arg"
    #           :must_match - a regexp that the flag's value must match
    #           :type - a class to convert the value to
    def initialize(names,options)
      super(names,options)
      @argument_name = options[:arg_name] || "arg"
      @default_value = options[:default_value]
      @must_match = options[:must_match]
      @type = options[:type]
    end

    def arguments_for_option_parser
      args = all_forms_a.map { |name| "#{name} VAL" }
      args << @must_match if @must_match
      args << @type if @type
      args
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
