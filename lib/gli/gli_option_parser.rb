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

    # Given the command-line argument array, returns and array of size 4:
    #
    # 0:: global options
    # 1:: command, as a Command
    # 2:: command-specific options
    # 3:: unparsed arguments
    def parse_options(args) # :nodoc:
      global_option_parser_factory = OptionParserFactory.new(@flags,@switches,@accepts)
      args                         = parse_global_options(global_option_parser_factory, args)
      command_name                 = args.shift
      global_options               = global_option_parser_factory.options_hash

      set_defaults(@flags,global_options)
      set_defaults(@switches,global_options)

      command = @command_finder.find_command(command_name)

      option_parser_factory = OptionParserFactory.for_command(command,@accepts)
      args                  = parse_command_options(option_parser_factory,command,args)
      command_options       = option_parser_factory.options_hash

      set_defaults(command.flags,command_options)
      set_defaults(command.switches,command_options)

      [global_options,command,command_options,args]
    end

  private

    def set_defaults(options_by_name,options_hash)
      options_by_name.each do |name,option|
        options_hash[name] = option.default_value if options_hash[name].nil?
      end
    end

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
  end
end
