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
