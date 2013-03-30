module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts,default_command = nil)
      @commands = commands
      @flags = flags
      @switches = switches
      @accepts = accepts
      @default_command = default_command
    end

    # Given the command-line argument array, returns and array of size 4:
    #
    # 0:: global options
    # 1:: command, as a Command
    # 2:: command-specific options
    # 3:: unparsed arguments
    def parse_options(args) # :nodoc:
      args_clone      = args.clone
      global_options  = {}
      command         = nil
      command_options = {}
      remaining_args  = nil

      global_option_parser_factory = OptionParserFactory.new(@flags,@switches,@accepts)
      args                         = parse_global_options(global_option_parser_factory, args)
      command_name                 = args.shift
      global_options               = global_option_parser_factory.options_hash

      @flags.each do |name,flag|
        global_options[name] = flag.default_value unless global_options[name]
      end
      @switches.each do |name,switch|
        global_options[name] = switch.default_value if global_options[name].nil?
      end

      command_name ||= @default_command || :help
      command = find_command(command_name)
      if Array(command).empty?
        raise UnknownCommand.new("Unknown command '#{command_name}'")
      elsif command.kind_of? Array
        raise UnknownCommand.new("Ambiguous command '#{command_name}'. It matches #{command.sort.join(',')}")
      end

      option_parser_factory = OptionParserFactory.for_command(command,@accepts)
      args                  = parse_command_options(option_parser_factory,command,args)
      command_options       = option_parser_factory.options_hash

      command.flags.each do |name,flag|
        command_options[name] = flag.default_value unless command_options[name]
      end
      command.switches.each do |name,switch|
        command_options[name] = switch.default_value if command_options[name].nil?
      end

      [global_options,command,command_options,args]
    end

  private

    def parse_command_options(option_parser_factory,command,args)
      option_block_parser = LegacyOptionBlockParser.new(
        option_parser_factory,
        lambda { |message| raise UnknownCommandArgument.new(message,command)}
      )
      option_block_parser.parse!(args)
    end

    def parse_global_options(option_parser_factory,args)
      GLIOptionBlockParser.new(option_parser_factory,UnknownGlobalArgument).parse!(args)
    end

    def find_command(name) # :nodoc:
      names_to_commands = {}
      @commands.each do |command_name,command|
        names_to_commands[command_name.to_s] = command
        Array(command.aliases).each do |command_alias|
          names_to_commands[command_alias.to_s] = command
        end
      end
      names_to_commands.fetch(name.to_s) do |command_to_match|
        find_command_by_partial_name(names_to_commands, command_to_match)
      end
    end

    def find_command_by_partial_name(names_to_commands, command_to_match)
      partial_matches = names_to_commands.keys.select { |command_name| command_name =~ /^#{command_to_match}/ }
      return names_to_commands[partial_matches[0]] if partial_matches.size == 1
      partial_matches
    end
  end
end
