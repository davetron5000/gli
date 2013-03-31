module GLI
  # Factory for creating an OptionParser based on app configuration and DSL calls
  class OptionParserFactory

    # Create an option parser factory for a command.  This has the added
    # feature of setting up -h and --help on the command if those
    # options aren't otherwise configured, e.g. to allow todo add --help as an
    # alternate to todo help add
    def self.for_command(command,accpets)
      self.new(command.flags,command.switches,accpets).tap { |factory|
        add_help_switches_to_command(factory.option_parser,command)
      }
    end

    # Create an OptionParserFactory for the given
    # flags, switches, and accepts
    def initialize(flags,switches,accepts)
      @options_hash = {}
      @option_parser = OptionParser.new do |opts|
        self.class.setup_accepts(opts,accepts)
        self.class.setup_options(opts,switches,@options_hash)
        self.class.setup_options(opts,flags,@options_hash)
      end
    end

    attr_reader :option_parser
    attr_reader :options_hash

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

    def self.add_help_switches_to_command(option_parser,command)
      help_args = %w(-h --help).reject { |_| command.has_option?(_) }

      unless help_args.empty?
        help_args << "Get help for #{command.name}"
        option_parser.on(*help_args) do
          raise CommandException.new(nil,command,0)
        end
      end
    end


  end
end
