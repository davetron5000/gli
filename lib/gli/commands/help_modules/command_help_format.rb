require 'erb'

module GLI
  module Commands
    module HelpModules
      class CommandHelpFormat
        def initialize(command,app,basic_invocation)
          @basic_invocation = basic_invocation
          @app = app
          @command = command
        end

        def format
          command_wrapper = TextWrapper.new(Terminal.instance.size[0],4 + @command.name.size + 3)
          wrapper = TextWrapper.new(Terminal.instance.size[0],4)
          flags_and_switches = @command.topmost_ancestor.flags.merge(@command.topmost_ancestor.switches).select { |_,option| option.associated_command == @command }
          options_description = OptionsFormatter.new(flags_and_switches).format
          commands_description = format_subcommands(@command)

          synopses = []
          if @command.commands.empty?
            one_line_usage = basic_usage(flags_and_switches)
            one_line_usage << @command.arguments_description
            synopses << one_line_usage
          else
            @command.commands.each do |name,sub|
              synopses << command_with_subcommand_usage(sub,flags_and_switches)
            end
          end

          COMMAND_HELP.result(binding)
        end

      private
        COMMAND_HELP = ERB.new(%q(NAME
    <%= @command.name %> - <%= command_wrapper.wrap(@command.description) %>

SYNOPSIS
<% synopses.each do |s| %>
    <%= s %>
<% end %>
<% unless @command.long_description.nil? %>

DESCRIPTION
    <%= wrapper.wrap(@command.long_description) %> 
<% end %> 
COMMAND OPTIONS
<%= options_description %>
<% unless @command.commands.empty? %>

COMMANDS
<%= commands_description %>
<% end %>),nil,'<>')

       def command_with_subcommand_usage(sub,flags_and_switches)
         usage = basic_usage(flags_and_switches)
         sub_options = @command.flags.merge(@command.switches).select { |_,o| o.associated_command == sub }
         usage << sub_options.map { |option_name,option| 
           all_names = [option.name,Array(option.aliases)].flatten
           all_names.map { |_| 
             CommandLineOption.name_as_string(_,false) + (option.kind_of?(Flag) ? " #{option.argument_name }" : '')
           }.join('|')
         }.map { |_| "[#{_}]" }.join(' ')
         usage << ' '
         usage << sub.name.to_s
         usage
       end

       def basic_usage(flags_and_switches)
         usage = @basic_invocation.dup
         usage << " [global options] #{path_to_command} "
         usage << "[command options] " unless global_flags_and_switches.empty?
         usage
       end

       def path_to_command
         path = []
         c = @command
         while c.kind_of? Command
           path.unshift(c.name)
           c = c.parent
         end
         path.join(' ')
       end

       def global_flags_and_switches
         @app.flags.merge(@app.switches)
       end

       def format_subcommands(command)
         formatter = ListFormatter.new(command.commands.values.map { |_| [ _.names,_.description] })
         StringIO.new.tap { |_| formatter.output(_) }.string
       end
      end
    end
  end
end
