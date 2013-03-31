module GLI
  class OptionParsingResult
    attr_reader :global_options
    attr_reader :command
    attr_reader :command_options
    attr_reader :arguments

    def initialize(global_options,command,command_options,arguments)
      @global_options  = global_options
      @command         = command
      @command_options = command_options
      @arguments       = arguments
    end

    # Get new OptionParsingResult where internal representation of options is an OpenStruct-style
    def using_openstruct
      self.class.new(Options.new(@global_options),@command,Options.new(@command_options),@arguments)
    end

    # Allows us to splat this object into blocks and methods expecting parameters in this order
    def to_a
      [@global_options,@command,@command_options,@arguments]
    end
  end
end
