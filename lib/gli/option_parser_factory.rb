module GLI
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
        setup_accepts(opts,@accepts)
        setup_options(opts,@switches,options)
        setup_options(opts,@flags,options)
      end
      [option_parser,options]
    end

  private

    def setup_accepts(opts,accepts)
      accepts.each do |object,block| 
        opts.accept(object) do |arg_as_string| 
          block.call(arg_as_string) 
        end
      end
    end

    def setup_options(opts,tokens,options)
      tokens.each do |_,token|
        opts.on(*token.arguments_for_option_parser) do |arg|
          [token.name,token.aliases].flatten.compact.each do |name|
            options[name] = arg
          end
        end
      end
    end

  end
end
