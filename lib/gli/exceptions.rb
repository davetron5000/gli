module GLI
  # Indicates that the command line invocation was bad
  class BadCommandLine < Exception
    def initialize(message)
      super(message)
    end
  end
end
