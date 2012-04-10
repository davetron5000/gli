module GLI
  module Commands
    # A command that calls other commands in order
    class CompoundCommand < Command
      def initialize(configuration,base,desc,arg_name,long_desc,skips_pre,skips_post)
        name = configuration.keys.first
        super([name].flatten,desc,arg_name,long_desc,skips_pre,skips_post)

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
