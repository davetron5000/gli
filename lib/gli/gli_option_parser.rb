module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts,default_command = nil,subcommand_option_handling_strategy=:legacy)
      @command_finder       = CommandFinder.new(commands,default_command || "help")
      @global_option_parser = GlobalOptionParser.new(OptionParserFactory.new(flags,switches,accepts),@command_finder)
      @accepts              = accepts
      @subcommand_option_handling_strategy = subcommand_option_handling_strategy
    end

    # Given the command-line argument array, returns an OptionParsingResult
    def parse_options(args) # :nodoc:
      option_parser_class = self.class.const_get("#{@subcommand_option_handling_strategy.capitalize}CommandOptionParser")
      OptionParsingResult.new.tap { |parsing_result|
        parsing_result.arguments = args
        parsing_result = @global_option_parser.parse!(parsing_result)
        option_parser_class.new(@accepts,@command_finder).parse!(parsing_result)
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
        parsing_result
      end
    end

    class NormalCommandOptionParser
      def initialize(accepts,command_finder)
        @accepts        = accepts
        @command_finder = command_finder
      end

      def error_handler
        lambda { |message,extra_error_context| 
          #STDERR.puts extra_error_context.flags.inspect
          #STDERR.puts extra_error_context.switches.inspect
          raise UnknownCommandArgument.new(message,extra_error_context)
        }
      end

      def parse!(parsing_result)
        parsed_command_options = {}
        command = parsing_result.command
        arguments = nil

        loop do
          option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
          option_block_parser         = CommandOptionBlockParser.new(option_parser_factory, self.error_handler)
          option_block_parser.command = command
          arguments                   = parsing_result.arguments

          arguments = option_block_parser.parse!(arguments)

          parsed_command_options[command] = option_parser_factory.options_hash_with_defaults_set!
          command_finder                  = CommandFinder.new(command.commands,command.get_default_command)
          next_command_name               = arguments.shift

          begin
            command = command_finder.find_command(next_command_name)
          rescue UnknownCommand
            arguments.unshift(next_command_name)
            break
          end
        end
        command_options = parsed_command_options[command]

        this_command          = command.parent
        child_command_options = command_options

        while this_command.kind_of?(command.class)
          this_command_options = parsed_command_options[this_command] || {}
          child_command_options[GLI::Command::PARENT] = this_command_options
          this_command = this_command.parent
          child_command_options = this_command_options
        end

        parsing_result.command_options = command_options
        parsing_result.command = command
        parsing_result.arguments = Array(arguments.compact)
        parsing_result
      end
    end

    class LegacyCommandOptionParser < NormalCommandOptionParser
      def parse!(parsing_result)
        command                     = parsing_result.command
        option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
        option_block_parser         = LegacyCommandOptionBlockParser.new(option_parser_factory, self.error_handler)
        option_block_parser.command = command

        parsing_result.arguments       = option_block_parser.parse!(parsing_result.arguments)
        parsing_result.command_options = option_parser_factory.options_hash_with_defaults_set!

        subcommand,args                = @command_finder.find_subcommand(command,parsing_result.arguments)
        parsing_result.command         = subcommand
        parsing_result.arguments       = args
      end
    end
  end
end
