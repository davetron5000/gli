module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts,default_command = nil)
      @commands = commands
      @flags = flags
      @switches = switches
      @accepts = accepts
      @command_finder = CommandFinder.new(@commands,default_command || "help")
    end

    # Given the command-line argument array, returns an OptionParsingResult
    def parse_options(args) # :nodoc:
      OptionParsingResult.new.tap { |parsing_result|
        parsing_result.arguments = args
        parse_global(parsing_result)
        parse_command(parsing_result)
      }
    end

  private

    def parse_global(parsing_result)
      global_option_parser_factory  = OptionParserFactory.new(@flags,@switches,@accepts)
      parsing_result.arguments      = GLIOptionBlockParser.new(global_option_parser_factory,UnknownGlobalArgument).parse!(parsing_result.arguments)
      command_name                  = parsing_result.arguments.shift
      parsing_result.global_options = global_option_parser_factory.options_hash_with_defaults_set!
      parsing_result.command        = @command_finder.find_command(command_name)
    end

    def parse_command(parsing_result)
      command                        = parsing_result.command
      option_parser_factory          = OptionParserFactory.for_command(command,@accepts)
      option_block_parser = LegacyOptionBlockParser.new(
        option_parser_factory,
        lambda { |message| raise UnknownCommandArgument.new(message,command)}
      )
      parsing_result.arguments       = option_block_parser.parse!(parsing_result.arguments)
      parsing_result.command_options = option_parser_factory.options_hash_with_defaults_set!
      subcommand,args                = @command_finder.find_subcommand(command,parsing_result.arguments)
      parsing_result.command         = subcommand
      parsing_result.arguments       = args
    end
  end
end
