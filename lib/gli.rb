require 'gli/command_line_token.rb'
require 'gli/command.rb'
require 'gli/switch.rb'
require 'gli/flag.rb'

# A means to define and parse a command line interface that works as
# Git's does, in that you specify global options, a command name, command
# specific options, and then command arguments.
module GLI
  extend self

  # Reset the GLI module internal data structures; mostly for testing
  def reset
    switches.clear
    flags.clear
    commands.clear
    clear_nexts
  end

  # describe the next switch, flag, or command
  def desc(description); @@next_desc = description; end
  # describe the argument name of the next flag
  def arg_name(name); @@next_arg_name = name; end
  # set the default value of the next flag
  def default_value(val); @@next_default_value = val; end

  # Create a flag, which is a switch that takes an argument
  def flag(names)
    flag = Flag.new(names,@@next_desc,@@next_arg_name,@@next_default_value)
    flags[flag.name] = flag
    clear_nexts
  end

  # Create a switch
  def switch(names)
    switch = Switch.new(names,@@next_desc)
    switches[switch.name] = switch
    clear_nexts
  end

  # Define a command.
  def command(names)
    command = Command.new(names,@@next_desc)
    commands[command.name] = command
    yield command
    clear_nexts
  end

  # Runs whatever command is needed based on the arguments.
  def run(args)
    commands[:help] = default_help_command if !commands[:help]
    begin
      global_options,command,options,arguments = parse_options(args)
      command.execute(global_options,options,arguments)
    rescue UnknownCommandException, UnknownArgumentException, MissingArgumentException => ex
      help = commands[:help]
      help.execute({},{},[])
    end
  end

  def default_help_command
    command = Command.new(:help,"Shows help")
    command.action = Proc.new do |global_options,options,arguments|
      if arguments.empty?
        puts "Commands:"
        output_command_tokens_for_help(commands)
      else
        command = commands[arguments[0].to_sym]
        if command
          puts "#{arguments[0]} - #{command.description}"
          output_command_tokens_for_help(command.switches.merge(command.flags))
        else
          puts "No such command #{arguments[0]}"
        end
      end
    end
    command
  end

  def output_command_tokens_for_help(tokens)
    max = 0
    tokens.values.each { |token| max = token.name_for_usage.length > max ? token.name_for_usage.length : max }
    names = tokens.keys.sort { |x,y| x.to_s <=> y.to_s }
    names.each do |name|
      puts tokens[name].usage(max,false)
    end
  end

  # Returns an array of four values:
  #  * global options (as a Hash)
  #  * Command 
  #  * command options (as a Hash)
  #  * arguments (as an Array)
  def parse_options(args)
    global_options,command,options,arguments = parse_options_helper(args.clone,Hash.new,nil,Hash.new,Array.new)
    flags.each { |name,flag| global_options[name] = flag.default_value if !global_options[name] }
    command.flags.each { |name,flag| options[name] = flag.default_value if !options[name] }
    return [global_options,command,options,arguments]
  end

  # Finds the index of the first non-flag
  # argument or -1 if there wasn't one.
  def find_non_flag_index(args)
    args.each_index do |i|
      return i if args[i] =~ /^[^\-]/;
      return i-1 if args[i] =~ /^\-\-$/;
    end
    -1;
  end

  alias :d :desc
  alias :f :flag
  alias :s :switch
  alias :c :command

  def clear_nexts
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
  end

  clear_nexts

  def flags; @@flags ||= {}; end
  def switches; @@switches ||= {}; end
  def commands; @@commands ||= {}; end

  # Recursive helper for parsing command line options
  # [args] the arguments that have yet to be processed
  # [global_options] the global options hash
  # [command] the Command that has been identified (or nil if not identified yet)
  # [command_options] options for Command
  # [arguments] the arguments for Command
  #
  # This works by finding the first non-switch/flag argument, and taking that sublist and trying to pick out
  # flags and switches.  After this is done, one of the following is true:
  #   * the sublist is empty - in this case, go again, as there might be more flags to parse
  #   * the sublist has a flag left in it - unknown flag; we bail
  #   * the sublist has a non-flag left in it - this is the command (or the start of the arguments list)
  #
  # This sort does the same thing in two phases; in the first phase, the command hasn't been identified, so
  # we are looking for global switches and flags, ending when we get the command.
  #
  # Once the command has been found, we start looking for command-specific flags and switches.
  # When those have been found, we know the rest of the argument list is arguments for the command
  def parse_options_helper(args,global_options,command,command_options,arguments)
    non_flag_i = find_non_flag_index(args)
    all_flags = false
    if non_flag_i == 0
      # no flags
      if !command
        command_name = args.shift
        command = commands[command_name.to_sym]
        raise(UnknownCommandException,"Unknown command '#{command_name}'") if !command
        return parse_options_helper(args,global_options,command,command_options,arguments)
      else
        return global_options,command,command_options,arguments | args
      end
    elsif non_flag_i == -1
      all_flags = true
    end

    try_me = args[0..non_flag_i]
    rest = args[(non_flag_i+1)..args.length]
    if all_flags
      try_me = args 
      rest = []
    end

    # Suck up whatever options we can
    switch_hash = switches
    flag_hash = flags
    options = global_options
    if command
      switch_hash = command.switches
      flag_hash = command.flags
      options = command_options
    end

    switch_hash.each do |name,switch|
      value = switch.get_value!(try_me)
      options[name] = value if !options[name]
    end

    flag_hash.each do |name,flag|
      value = flag.get_value!(try_me)
      options[name] = value if !options[name]
    end

    if try_me.empty?
      return [global_options,command,command_options,arguments] if rest.empty?
      # If we have no more options we've parsed them all
      # and rest may have more
      return parse_options_helper(rest,global_options,command,command_options,arguments)
    else
      if command
        check = rest
        check = rest | try_me if all_flags 
        check.each() do |arg| 
          if arg =~ /^\-\-$/
            try_me.delete arg
            break 
          end
          raise(UnknownArgumentException,"Unknown argument #{arg}") if arg =~ /^\-/ 
        end
        return [global_options,command,command_options,try_me | rest]
      else
        # Now we have our command name
        command_name = try_me.shift
        raise(UnknownArgumentException,"Unknown argument #{command_name}") if command_name =~ /^\-/

        command = commands[command_name.to_sym]
        raise(UnknownCommandException,"Unknown command '#{command_name}'") if !command

        return parse_options_helper(rest,global_options,command,command_options,arguments)
      end
    end

  end

  class UnknownArgumentException < Exception
  end

  class UnknownCommandException < Exception
  end

  class MissingArgumentException < Exception
  end
end
