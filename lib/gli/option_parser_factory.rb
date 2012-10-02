module GLI
  # Factory for creating an OptionParser based on app configuration and DSL calls
  class OptionParserFactory
    # Create an OptionParserFactory for the given
    # flags, switches, and accepts
    def initialize(flags,switches,accepts)
      @flags = flags
      @switches = switches
      @accepts = accepts
    end

    # Return an option parser to parse the given flags, switches and accepts
    def option_parser
      options = {}
      option_parser = OptionParser.new do |opts|
        self.class.setup_accepts(opts,@accepts)
        self.class.setup_options(opts,@switches,options)
        self.class.setup_options(opts,@flags,options)
      end
      [option_parser,options]
    end

  private

    def self.setup_accepts(opts,accepts)
      accepts.each do |object,block|
        opts.accept(object) do |arg_as_string|
          block.call(arg_as_string)
        end
      end
    end

    def self.setup_options(opts,tokens,options)
      tokens.each do |ignore,token|
        opts.on(*token.arguments_for_option_parser) do |arg|
          [token.name,token.aliases].flatten.compact.map(&:to_s).each do |name|
            options[name] = arg
            options[name.to_sym] = arg
          end
        end
      end
    end

  end
end
