require 'gli'
require 'fileutils'

module GLI
  class RDocCommand < Command # :nodoc:

    def initialize
      super(:rdoc,'Generates RDoc (and other types of documentation) for your command line interface')
      self.desc 'Create a very basic scaffold for a cheat-style cheatsheet, in addition to rdoc'
      self.switch 'cheatsheet'
      self.desc 'Include a manapage suitable for gem man, in addition to rdoc'
      self.switch 'manpage'
      self.desc 'Do not create rdoc'
      self.switch 'no-rdoc'
    end

    def execute(g,options,a)
      create_rdoc unless options[:'no-rdoc']
      create_manpage if options[:manpage]
      create_cheatsheet if options[:cheatsheet]
    end

    def create_cheatsheet
      File.open("#{GLI.program_name}.cheat",'w') do |file|
        file << GLI.program_name
        file << "\n"
        file << GLI.program_name.length.times.inject("") { |a,x| a + "=" }
        file << "\n"
        file << "\n"
        file << "Installation:\n"
        file << "$ gem install #{GLI.program_name}\n\n"
        GLI.commands.values.sort.each do |command|
          next if command == self
          file << command.description
          file << "\n"
          [command.name,command.aliases].flatten.each do |name|
            next unless name
            file << "$ #{GLI.program_name} #{name} #{command.arguments_description}\n"
          end
          file << "\n"
        end
      end
    end

    def create_manpage
    end

    def create_rdoc
      File.open("#{GLI.program_name}.rdoc",'w') do |file|
        file << "= <tt>#{GLI.program_name}</tt>\n\n"
        if GLI.program_desc
          file << GLI.program_desc
          file << "\n\n"
        end
        file << "    "
        file << GLI.program_name
        file << " "
        global_options = GLI.switches.merge(GLI.flags)
        if (global_options && global_options.length > 0)
          file << "[global options] "
        end
        file << "command_name"
        file << " [command-specific options]"
        file << " [--] arguments...\n\n"
        file << "* Use the command +help+ to get a summary of commands\n"
        file << "* Use the command <tt>help command_name</tt> to get a help for +command_name+\n"
        file << "* Use <tt>--</tt> to stop command line argument processing; useful if your arguments have dashes in them\n"
        file << "\n"
        if (global_options && global_options.length > 0)
          file << "== Global Options\n"
          file << "These options are available for any command and are specified before the name of the command\n\n"
          output_flags(file,global_options)
        end
        file << "== Commands\n"
        GLI.commands.values.sort.each do |command|
          next if command == self
          file << "[<tt>#{command.name}</tt>] #{command.description}\n"
        end
        file << "\n"

        GLI.commands.values.sort.each do |command|
          next if command == self
          file << "=== <tt>#{command.name} #{command.arguments_description}</tt>\n\n"
          file << "#{command.description}\n\n"
          if command.aliases
            file << "*Aliases*\n"
            command.aliases.each do |al|
              file << "* <tt><b>#{al}</b></tt>\n"
            end 
            file << "\n"
          end
          all_options = command.switches.merge(command.flags)
          file << "#{command.long_description}\n\n" if command.long_description
          if (all_options && all_options.length > 0)
            file << "==== Options\n"
            file << "These options are specified *after* the command.\n\n"
            output_flags(file,all_options)
          end
        end
      end
    end

    def output_flags(file,flags)
      flags.values.sort.each do |flag|
        file << "[<tt>#{flag.usage}</tt>] #{flag.description}"
        if flag.kind_of? Flag
          file << " <i>( default: <tt>#{flag.default_value}</tt>)</i>" if flag.default_value
        end
        file << "\n"
        if flag.long_description
          file << "\n"
          # 12 is: 4 for tt, 5 for /tt, 2 for the brackets and 1 for spacing
          (flag.usage.length + 12).times { file << " " }
          file << "#{flag.long_description}\n\n"
        end
      end
    end
  end
end
