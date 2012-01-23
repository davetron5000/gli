require 'gli/command'

module GLI
  module Commands
    # The help command used for the two-level interactive help system
    class Help < Command
      def initialize(app)
        super(:help,
              'Shows a list of commands or help for one command',
              'command',
              'Gets help for the application or its commands. Can also list the commands in a way helpful to creating a bash-style completion function',
              true,
              true)
        @app = app
        action do |global_options,options,arguments|
          show_help(global_options,options,arguments,$stdout)
        end
      end

    private

      # Given a list of two-element lists, formats on the terminal 
      class ListFormatter
        def initialize(list)
          @list = list
        end

        # Output the list to the output_device
        def output(output_device)
          max_width = @list.map { |_| _[0].length }.max
          wrapper = TextWrapper.new(Terminal.instance.size[0],4 + max_width + 3)
          @list.each do |(name,description)|
            output_device.printf("    %-#{max_width}s - %s\n",name,wrapper.wrap(String(description).strip))
          end
        end
      end

      # Handles wrapping text
      class TextWrapper
        # Create a text_wrapper wrapping at the given width,
        # and indent.
        def initialize(width,indent)
          @width = width
          @indent = indent
        end

        # Return a wrapped version of text, assuming that the first line has already been
        # indented by @indent characters.  Resulting text does NOT have a newline in it.
        def wrap(text)
          wrapped_text = ''
          current_line = ''
          current_line_length = @indent

          words = text.split(/\s+/)
          current_line = words.shift
          current_line_length += current_line.length

          words.each do |word|
            if current_line_length + word.length + 1 > @width
              wrapped_text << current_line << "\n"
              current_line = ''
              @indent.times { current_line << ' ' }
              current_line << word
              current_line_length = @indent + word.length
            else
              if current_line == ''
                current_line << word
              else
                current_line << ' ' << word
              end
              current_line_length += (word.length + 1)
            end
          end
          wrapped_text << current_line
          wrapped_text
        end
      end

      def show_help(global_options,options,arguments,out)
        if arguments.empty?
          out.puts @app.program_desc
          out.puts
          out.puts usage_string
          unless global_flags_and_switches.empty?
            output_global_flags_and_switches(out)
          end
          out.puts
          out.puts "Commands:"
          command_formatter = ListFormatter.new(@app.commands.values.map { |command|
            [[command.name,Array(command.aliases)].flatten.join(', '),command.description]
          })
          command_formatter.output(out)
        else
          command = find_command(arguments[0])
          if command.nil?
            $stderr.puts "error: Unknown command '#{arguments[0]}'.  Use 'gli help' for a list of commands."
          else
            out.puts command.name
            out.puts command.description
            out.puts command.long_description
            command.switches.merge(command.flags).values.each do |option|
              puts "-#{option.name}"
              puts option.description
            end
          end
        end
      end

      def find_command(command_name)
        @app.commands.values.select { |command|
          if [command.name,Array(command.aliases)].flatten.map(&:to_s).any? { |_| _ == command_name }
            command
          end
        }.first
      end

      def output_global_flags_and_switches(out)
        out.puts
        out.puts "Global Options:"
        list_formatter = ListFormatter.new(global_flags_and_switches.values.sort { |a,b| 
          a.name.to_s <=> b.name.to_s 
        }.map { |option|
          if option.respond_to? :argument_name
            [option_names_for_help_string(option,option.argument_name),option.description]
          else
            [option_names_for_help_string(option),option.description]
          end
        })
        list_formatter.output(out)
      end

      def global_flags_and_switches
        @app.flags.merge(@app.switches)
      end

      def usage_string
        "usage: #{File.basename($0)} ".tap do |string|
          string << "[global options] " unless global_flags_and_switches.empty?
          string << "command "
          string << "[command options] [arguments...]"
        end
      end

      def option_names_for_help_string(option,arg_name=nil)
        names = [option.name,Array(option.aliases)].flatten
        names = names.map { |name|
          name.length == 1 ? "-#{name}" : "--#{name}"
        }
        if arg_name.nil?
          names.join(', ')
        else
          if names[-1] =~ /^--/
            names.join(', ') + "=#{arg_name}"
          else
            names.join(', ') + " #{arg_name}"
          end
        end
      end
    end
  end
end
