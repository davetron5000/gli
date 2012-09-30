require 'erb'
require 'gli/command'
require 'gli/terminal'
require 'gli/commands/help_modules/list_formatter'
require 'gli/commands/help_modules/text_wrapper'
require 'gli/commands/help_modules/one_line_wrapper'
require 'gli/commands/help_modules/tty_only_wrapper'
require 'gli/commands/help_modules/options_formatter'
require 'gli/commands/help_modules/global_help_format'
require 'gli/commands/help_modules/command_help_format'
require 'gli/commands/help_modules/help_completion_format'
require 'gli/commands/help_modules/command_finder'
require 'gli/commands/help_modules/arg_name_formatter'

module GLI
  module Commands
    SORTERS = {
      :manually => lambda { |list| list },
      :alpha    => lambda { |list| list.sort },
    }

    WRAPPERS = {
      :to_terminal => HelpModules::TextWrapper,
      :never       => HelpModules::OneLineWrapper,
      :one_line    => HelpModules::OneLineWrapper,
      :tty_only    => HelpModules::TTYOnlyWrapper,
    }
    # The help command used for the two-level interactive help system
    class Help < Command
      def initialize(app,output=$stdout,error=$stderr)
        super(:names => :help,
              :description => 'Shows a list of commands or help for one command',
              :arguments_name => 'command',
              :long_desc => 'Gets help for the application or its commands. Can also list the commands in a way helpful to creating a bash-style completion function',
              :skips_pre => true,
              :skips_post => true,
              :skips_around => true)
        @app = app
        @sorter = SORTERS[@app.help_sort_type]
        @text_wrapping_class = WRAPPERS[@app.help_text_wrap_type]

        desc 'List commands one per line, to assist with shell completion'
        switch :c

        action do |global_options,options,arguments|
          show_help(global_options,options,arguments,output,error)
        end
      end

    private

      def show_help(global_options,options,arguments,out,error)
        command_finder = HelpModules::CommandFinder.new(@app,arguments,error)
        if options[:c]
          help_output = HelpModules::HelpCompletionFormat.new(@app,command_finder,arguments).format
          out.puts help_output unless help_output.nil?
        elsif arguments.empty? || options[:c]
          out.puts HelpModules::GlobalHelpFormat.new(@app,@sorter,@text_wrapping_class).format
        else
          name = arguments.shift
          command = command_finder.find_command(name)
          unless command.nil?
            out.puts HelpModules::CommandHelpFormat.new(command,@app,File.basename($0).to_s,@sorter,@text_wrapping_class).format
          end
        end
      end

    end
  end
end
