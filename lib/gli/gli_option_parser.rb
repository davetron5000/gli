module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts)
      @commands = commands
      @flags = flags
      @switches = switches
      @accepts = accepts
    end

    # Given the command-line argument array, returns and array of size 4:
    #
    # 0:: global options
    # 1:: command, as a Command
    # 2:: command-specific options
    # 3:: unparsed arguments
    def parse_options(args) # :nodoc:
      args_clone = args.clone
      global_options = {}
      command = nil
      command_options = {}
      remaining_args = nil

      global_options,command_name,args = parse_global_options(OptionParserFactory.new(@flags,@switches,@accepts), args)
      @flags.each do |name,flag| 
        global_options[name] = flag.default_value unless global_options[name]
      end

      command_name ||= @default_command || :help
      command = find_command(command_name)
      if Array(command).empty?
        raise UnknownCommand.new("Unknown command '#{command_name}'")
      elsif command.kind_of? Array
        raise UnknownCommand.new("Ambiguous command '#{command_name}'. It matches #{command.sort.join(',')}")
      end

      command_options,args = parse_command_options(OptionParserFactory.new(command.flags,command.switches,@accepts),
                                                   command,
                                                   args)

      command.flags.each do |name,flag| 
        command_options[name] = flag.default_value unless command_options[name]
      end
      command.switches.each do |name,switch| 
        command_options[name] = switch.default_value unless command_options[name] 
      end

      [global_options,command,command_options,args]
    end

  private

    def parse_command_options(option_parser_factory,command,args)
      option_parser,command_options = option_parser_factory.option_parser
      option_parser.parse!(args)
      [command_options,args]
    rescue OptionParser::InvalidOption => ex
      raise UnknownCommandArgument.new("Unknown option #{ex.args.join(' ')}",command)
    rescue OptionParser::InvalidArgument => ex
      raise UnknownCommandArgument.new("#{ex.reason}: #{ex.args.join(' ')}",command)
    end

    def parse_global_options(option_parser_factory,args,&error_handler)
      if error_handler.nil?
        error_handler = lambda { |message|
          raise UnknownGlobalArgument.new(message)
        }
      end
      option_parser,global_options = option_parser_factory.option_parser
      command = nil
      option_parser.order!(args) do |non_option|
        command = non_option
        break
      end
      [global_options,command,args]
    rescue OptionParser::InvalidOption => ex
      error_handler.call("Unknown option #{ex.args.join(' ')}")
    rescue OptionParser::InvalidArgument => ex
      error_handler.call("#{ex.reason}: #{ex.args.join(' ')}")
    end

    def find_command(name) # :nodoc:
      names_to_commands = {}
      @commands.each do |command_name,command|
        names_to_commands[command_name.to_s] = command
        Array(command.aliases).each do |command_alias|
          names_to_commands[command_alias.to_s] = command
        end
      end
      name = name.to_s
      return names_to_commands[name] if names_to_commands[name]
      # Now try to match on partial names
      partial_matches = names_to_commands.keys.select { |command_name| command_name =~ /^#{name}/ }
      return names_to_commands[partial_matches[0]] if partial_matches.size == 1
      partial_matches
    end
  end
end
