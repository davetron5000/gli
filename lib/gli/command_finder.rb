module GLI
  class CommandFinder
    attr_accessor :options

    DEFAULT_OPTIONS = {
      default_command: nil
    }

    def initialize(commands, options = {})
      self.options = DEFAULT_OPTIONS.merge(options)
      self.commands_with_aliases = expand_with_aliases(commands)
    end

    def find_command(name)
      name = String(name || options[:default_command]).strip
      raise UnknownCommand.new("No command name given nor default available") if name == ''

      command_found = commands_with_aliases.fetch(name) do |command_to_match|
        find_command_by_partial_name(commands_with_aliases, command_to_match)
      end

      if Array(command_found).empty?
        raise UnknownCommand.new("Unknown command '#{name}'")
      elsif command_found.kind_of? Array
        raise AmbiguousCommand.new("Ambiguous command '#{name}'. It matches #{command_found.sort.join(',')}")
      end
      command_found
    end

  private
    attr_accessor :commands_with_aliases

    def expand_with_aliases(commands)
      expanded = {}
      commands.each do |command_name, command|
        expanded[command_name.to_s] = command
        Array(command.aliases).each do |command_alias|
          expanded[command_alias.to_s] = command
        end
      end
      expanded
    end

    def find_command_by_partial_name(commands_with_aliases, command_to_match)
      partial_matches = commands_with_aliases.keys.select { |command_name| command_name =~ /^#{command_to_match}/ }
      return commands_with_aliases[partial_matches[0]] if partial_matches.size == 1
      partial_matches
    end
  end
end
