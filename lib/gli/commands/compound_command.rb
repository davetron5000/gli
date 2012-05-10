module GLI
  module Commands
    # A command that calls other commands in order
    class CompoundCommand < Command
      # base:: object that respondes to #commands
      # configuration:: Array of arrays: index 0 is the array of names of this command and index 0
      #                 is the names of the compound commands.
      def initialize(base,configuration,options={})
        name = configuration.keys.first
        super(options.merge(:names => [name]))

        command_names = configuration[name]

        check_for_unknown_commands!(base,command_names)

        @commands = command_names.map { |_| find_command(base,_) }
      end

      def execute(global_options,options,arguments)
        @commands.each { |_| _.execute(global_options,options,arguments) }
      end

    private 

      def check_for_unknown_commands!(base,command_names)
        known_commands = base.commands.keys.map(&:to_s)
        unknown_commands = command_names.map(&:to_s) - known_commands

        unless unknown_commands.empty?
          raise "Unknown commands #{unknown_commands.join(',')}"
        end
      end

      def find_command(base,name)
        base.commands.values.find { |command| command.name == name }
      end

    end
  end
end
