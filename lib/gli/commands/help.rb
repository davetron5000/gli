require 'erb'
require 'gli/command'
require 'gli/terminal'
require 'gli/commands/help_modules/list_formatter'
require 'gli/commands/help_modules/text_wrapper'
require 'gli/commands/help_modules/options_formatter'
require 'gli/commands/help_modules/global_help_format'
require 'gli/commands/help_modules/command_help_format'

module GLI
  module Commands
    # The help command used for the two-level interactive help system
    class Help < Command
      def initialize(app,output=$stdout,error=$stderr)
        super(:help,
              'Shows a list of commands or help for one command',
              'command',
              'Gets help for the application or its commands. Can also list the commands in a way helpful to creating a bash-style completion function',
              true,
              true)
        @app = app
        action do |global_options,options,arguments|
          show_help(global_options,options,arguments,output,error)
        end
      end

    private

      def show_help(global_options,options,arguments,out,error)
        if arguments.empty?
          out.puts HelpModules::GlobalHelpFormat.new(@app).format
        else
          command = find_command(arguments[0])
          if command.nil?
            error.puts "error: Unknown command '#{arguments[0]}'.  Use 'gli help' for a list of commands."
            return
          end
          out.puts HelpModules::CommandHelpFormat.new(command,@app,File.basename($0).to_s).format
        end
      end

      def find_command(command_name)
        @app.commands.values.select { |command|
          if [command.name,Array(command.aliases)].flatten.map(&:to_s).any? { |_| _ == command_name }
            command
          end
        }.first
      end
    end
  end
end
