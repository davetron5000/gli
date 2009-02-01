require 'gli'
require 'gli/command'

module GLI
  class DefaultHelpCommand < Command
    def initialize
      super(:help,'Shows list of commands or help for one command','[command]')
    end

    def execute(global_options,options,arguments)
      if arguments.empty?
        list_global_flags
        list_commands
      else
        list_one_command_help(arguments[0])
      end
    end

    private

    def list_global_flags
      usage = "usage: #{GLI.program_name} command"
      all_options = GLI.switches.merge(GLI.flags)
      if !all_options.empty?
        usage += ' [options]'
      end
      puts usage
      puts
      puts 'Options:' if !all_options.empty?
      output_command_tokens_for_help(all_options)
      puts if !all_options.empty?
    end

    def list_commands
      puts 'Commands:'
      output_command_tokens_for_help(GLI.commands,:names)
    end

    def list_one_command_help(command_name)
      command = GLI.commands[command_name.to_sym]
      if command
        puts command.usage
        description = wrap(command.description,4)
        puts "    #{description}"
        all_options = command.switches.merge(command.flags)
        if !all_options.empty?
          puts
          puts "Options:"
          output_command_tokens_for_help(all_options)
        end
      else
        puts "No such command #{command_name}"
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
        printf "    %-#{max}s - %s\n",token.send(usage_name),description
      end
    end
  end

  private

  # Wraps the line at the given column length, using the given line padding.
  # Assumes that the first line doesn't need the padding, as its filled
  # up with other stuff
  def wrap(line,pad_length=0,line_length=80)
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
