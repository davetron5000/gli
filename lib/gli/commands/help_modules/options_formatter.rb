module GLI
  module Commands
    module HelpModules
      class OptionsFormatter
        def initialize(flags_and_switches)
          @flags_and_switches = flags_and_switches
        end

        def format
          list_formatter = ListFormatter.new(@flags_and_switches.values.sort { |a,b| 
            a.name.to_s <=> b.name.to_s 
          }.map { |option|
            if option.respond_to? :argument_name
              [option_names_for_help_string(option,option.argument_name),option.description]
            else
              [option_names_for_help_string(option),option.description]
            end
          })
          stringio = StringIO.new
          list_formatter.output(stringio)
          stringio.string
        end

        private

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
end
