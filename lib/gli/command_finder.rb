module GLI
  class CommandFinder
    # Initialize a finder on the given list of commands, using default_command as the default if none found
    def initialize(commands,default_command)
      @default_command = default_command
      @names_to_commands = {}
      commands.each do |command_name,command|
        @names_to_commands[command_name.to_s] = command
        Array(command.aliases).each do |command_alias|
          @names_to_commands[command_alias.to_s] = command
        end
      end
    end

    # Finds the command with the given name, allowing for partial matches.  Returns the command named by
    # the default command if no command with +name+ matched
    def find_command(name)
      name ||= @default_command

      raise UnknownCommand.new("No command name given nor default available") if String(name).strip == ''

      command_found = @names_to_commands.fetch(name.to_s) do |command_to_match|
        find_command_by_partial_name(@names_to_commands, command_to_match)
      end
      if Array(command_found).empty?
        raise UnknownCommand.new("Unknown command '#{name}'")
      elsif command_found.kind_of? Array
        raise UnknownCommand.new("Ambiguous command '#{name}'. It matches #{command_found.sort.join(',')}")
      end
      command_found
    end

    def find_subcommand(command,arguments)
      arguments = Array(arguments)
      command_name = if arguments.empty?
                       nil
                     else
                       arguments.first
                     end

      default_command = command.get_default_command
      finder = CommandFinder.new(command.commands,default_command.to_s)

      begin
        results = [finder.find_command(command_name),arguments[1..-1]]
        find_subcommand(results[0],results[1])
      rescue UnknownCommand
        begin
          results = [finder.find_command(default_command.to_s),arguments]
          find_subcommand(results[0],results[1])
        rescue UnknownCommand
          [command,arguments]
        end
      end
    end

  private

    def find_command_by_partial_name(names_to_commands, command_to_match)
      partial_matches = names_to_commands.keys.select { |command_name| command_name =~ /^#{command_to_match}/ }
      return names_to_commands[partial_matches[0]] if partial_matches.size == 1
      partial_matches
    end
  end
end
