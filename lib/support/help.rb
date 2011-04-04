require 'gli'
require 'gli/command'
require 'gli/terminal'

module GLI
  class DefaultHelpCommand < Command #:nodoc:
    @@output = $stdout
    @@skips_pre = true
    @@skips_post = true

    # Exposed for testing
    def self.output_device=(o); @@output = o; end

    # To override the default behavior of the help command, which is
    # to NOT run the pre block, use this.
    def self.skips_pre=(skips_pre)
      @@skips_pre = skips_pre
    end

    # To override the default behavior of the help command, which is
    # to NOT run the post block, use this.
    def self.skips_post=(skips_post)
      @@skips_post = skips_post
    end

    def initialize(version,*omit_from_list)
      @omit_from_list = omit_from_list
      @version = version
      super(:help,
            'Shows list of commands or help for one command',
            '[command]',
            'Gets help for the application or its commands.  Can also list the commands in a way helpful to creating a bash-style completion function')
      self.desc 'List all commands one line at a time, for use with shell completion ([command] argument is partial command to match)'
      self.switch [:c,:completion]
    end

    def skips_pre; @@skips_pre; end
    def skips_post; @@skips_post; end

    def execute(global_options,options,arguments)
      if options[:c]
        names = commands_to_show.reduce([]) do |memo,obj|
          memo << obj[0]
          memo << obj[1].aliases
          memo = memo.flatten
        end
        names.map! { |name| name.to_s } 
        if arguments && arguments.size > 0
          names = names.select { |name| name =~ /^#{arguments[0]}/ }
        end
        names.sort.each do |command|
          next if command.empty?
          @@output.puts command
        end
      else
        if arguments.empty?
          list_global_flags
          list_commands
        else
          list_one_command_help(arguments[0])
        end
      end
    end

    private

    def list_global_flags
      if GLI.program_desc
        @@output.puts wrap(GLI.program_desc,0)
        @@output.puts
      end
      usage = "usage: #{GLI.program_name} "
      all_options = GLI.switches.merge(GLI.flags)
      if !all_options.empty?
          usage += "[global options] "
      end
      usage += "command"
      usage += ' [command options]'
      @@output.puts usage
      @@output.puts
      if @version
        @@output.puts "Version: #{@version}"
        @@output.puts
      end
      @@output.puts 'Global Options:' if !all_options.empty?
      output_command_tokens_for_help(all_options)
      @@output.puts if !all_options.empty?
    end

    def list_commands
      @@output.puts 'Commands:'
      output_command_tokens_for_help(commands_to_show,:names)
    end

    def commands_to_show
      GLI.commands.reject{ |name,c| @omit_from_list.include?(c) }
    end

    def list_one_command_help(command_name)
      command = GLI.find_command(command_name)
      if command
        @@output.puts command.usage
        description = wrap(command.description,4)
        @@output.puts "    #{description}"
        if command.long_description
          @@output.puts
          @@output.puts "    #{wrap(command.long_description,4)}"
        end
        all_options = command.switches.merge(command.flags)
        if !all_options.empty?
          @@output.puts
          @@output.puts "Command Options:"
          output_command_tokens_for_help(all_options)
        end
      else
        @@output.puts "No such command #{command_name}"
      end
    end

    def output_command_tokens_for_help(tokens,usage_name=:usage)
      max = 0
      tokens.values.each do |token| 
        len = token.send(usage_name).length
        if len > max 
          max = len
        end
      end
      names = tokens.keys.sort { |x,y| x.to_s <=> y.to_s }
      names.each do |name|
        token = tokens[name]
        description = token.description || ''
        if token.kind_of? Flag 
          description += " (default: #{token.default_value})" if token.default_value
        end
        description = wrap(description,max+7)
        string = sprintf "    %-#{max}s - %s",token.send(usage_name),description
        @@output.puts string
      end
    end
  end

  private

  # Wraps the line at the given column length, using the given line padding.
  # Assumes that the first line doesn't need the padding, as its filled
  # up with other stuff
  def wrap(line,pad_length=0,line_length=nil)
    if line_length.nil?
      line_length = Terminal.instance.size[0]
    end
    line_padding = sprintf("%#{pad_length}s",'')
    words = line.split(/\s+/)
    return line if !words || words.empty?
    wrapped = ''
    while wrapped.length + line_padding.length < line_length
      wrapped += ' ' if wrapped.length > 0
      word = words.shift
      if (wrapped.length + line_padding.length + word.length > line_length)
        words.unshift word
        break;
      end
      wrapped += word
      return wrapped if words.empty?
    end
    wrapped += "\n"
    this_line = line_padding
    words.each do |word|
      if this_line.length + word.length > line_length
        wrapped += this_line
        wrapped += "\n"
        this_line = line_padding + word
      else
        this_line += ' ' if this_line.length > line_padding.length
        this_line += word
      end
    end
    wrapped.chomp!
    wrapped + "\n" + this_line
  end
end
