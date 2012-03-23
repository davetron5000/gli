require 'erb'

module GLI
  module Commands
    module HelpModules
      class CommandHelpFormat
        def initialize(command,app)
          @command = command
            @app = app
        end

        def format
          command_help(@command)
        end

      private
        COMMAND_HELP = ERB.new(%q(NAME
    <%= cmd.name %> - <%= command_wrapper.wrap(cmd.description) %>

SYNOPSIS

<% synopses.each do |s| %>
    <%= s %>
<% end  %>
<% unless cmd.long_description.nil? %>

DESCRIPTION

    <%= wrapper.wrap(cmd.long_description) %> 
<% end %> 
OPTIONS

<%= options_description %>
<% unless cmd.commands.empty? %>

COMMANDS

<%= commands_description %>
<% end %>
                                 ),nil,'<>')

       def command_help(cmd)
         command_wrapper = TextWrapper.new(Terminal.instance.size[0],4 + cmd.name.size + 3)
         wrapper = TextWrapper.new(Terminal.instance.size[0],4)
         flags_and_switches = cmd.flags.merge(cmd.switches).select { |_,option| option.associated_command == cmd }
         options_description = OptionsFormatter.new(flags_and_switches).format
         commands_description = format_subcommands(cmd)

         synopses = []
         if cmd.commands.empty?
           synopses << one_line_usage(cmd,flags_and_switches)
         else
           cmd.commands.each do |name,sub|
             synopses << command_with_subcommand_usage(cmd,sub,flags_and_switches)
           end
         end

         COMMAND_HELP.result(binding)
       end

       def command_with_subcommand_usage(cmd,sub,flags_and_switches)
         usage = basic_usage(cmd,flags_and_switches)
         sub_options = cmd.flags.merge(cmd.switches).select { |_,o| o.associated_command == sub }
         usage << sub_options.map { |option_name,option| 
           all_names = [option.name,Array(option.aliases)].flatten
           all_names.map { |_| 
             CommandLineOption.name_as_string(_,false) + (option.kind_of?(Flag) ? " #{option.argument_name }" : '')
           }.join('|')
         }.map { |_| "[#{_}]" }.join(' ')
         usage << ' '
         usage << sub.name.to_s
       end

       def one_line_usage(cmd,flags_and_switches)
         one_line_usage = basic_usage(cmd,flags_and_switches)
         one_line_usage << cmd.arguments_description
       end

       def basic_usage(cmd,flags_and_switches)
         usage = File.basename($0).to_s
         usage << " #{cmd.name} "
         usage << "[options] " unless flags_and_switches.empty?
         usage
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
