module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts,default_command = nil)
      @command_finder       = CommandFinder.new(commands,default_command || "help")
      @global_option_parser = GlobalOptionParser.new(OptionParserFactory.new(flags,switches,accepts),@command_finder)
      @accepts              = accepts
    end

    # Given the command-line argument array, returns an OptionParsingResult
    def parse_options(args) # :nodoc:
      OptionParsingResult.new.tap { |parsing_result|
        parsing_result.arguments = args
        @global_option_parser.parse!(parsing_result)
        CommandOptionParser.new(OptionParserFactory.for_command(parsing_result.command,@accepts),@command_finder).parse!(parsing_result)
      }
    end

  private

    class GlobalOptionParser
      def initialize(option_parser_factory,command_finder)
        @option_parser_factory = option_parser_factory
        @command_finder        = command_finder
      end

      def parse!(parsing_result)
        parsing_result.arguments      = GLIOptionBlockParser.new(@option_parser_factory,UnknownGlobalArgument).parse!(parsing_result.arguments)
        command_name                  = parsing_result.arguments.shift
        parsing_result.global_options = @option_parser_factory.options_hash_with_defaults_set!
        parsing_result.command        = @command_finder.find_command(command_name)
      end
    end

    class CommandOptionParser
      def initialize(option_parser_factory,command_finder)
        @option_parser_factory = option_parser_factory
        @command_finder        = command_finder
      end

      def parse!(parsing_result)
        command                        = parsing_result.command
        option_block_parser = LegacyOptionBlockParser.new(
          @option_parser_factory,
          lambda { |message| raise UnknownCommandArgument.new(message,command)}
        )
        parsing_result.arguments       = option_block_parser.parse!(parsing_result.arguments)
        parsing_result.command_options = @option_parser_factory.options_hash_with_defaults_set!
        subcommand,args                = @command_finder.find_subcommand(command,parsing_result.arguments)
        parsing_result.command         = subcommand
        parsing_result.arguments       = args
      end
    end
  end
end
