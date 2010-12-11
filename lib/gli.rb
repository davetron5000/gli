require 'gli/command_line_token.rb'
require 'gli/command.rb'
require 'gli/switch.rb'
require 'gli/flag.rb'
require 'gli/options.rb'
require 'gli/exceptions.rb'
require 'gli_version.rb'
require 'support/help.rb'
require 'support/rdoc.rb'
require 'support/initconfig.rb'
require 'etc'

# A means to define and parse a command line interface that works as
# Git's does, in that you specify global options, a command name, command
# specific options, and then command arguments.
module GLI
  extend self

  @@program_name = $0.split(/\//)[-1]
  @@post_block = nil
  @@pre_block = nil
  @@error_block = nil
  @@config_file = nil
  @@use_openstruct = false
  @@version = nil

  # Reset the GLI module internal data structures; mostly for testing
  def reset
    switches.clear
    flags.clear
    commands.clear
    @@version = nil
    @@config_file = nil
    @@use_openstruct = false
    clear_nexts
  end

  # describe the next switch, flag, or command.  This should be a
  # short, one-line description
  def desc(description); @@next_desc = description; end

  # Provide a longer, more detailed description.  This
  # will be reformatted and wrapped to fit in 80 columns
  def long_desc(long_desc); @@next_long_desc = long_desc; end

  # describe the argument name of the next flag
  def arg_name(name); @@next_arg_name = name; end

  # set the default value of the next flag
  def default_value(val); @@next_default_value = val; end

  # Create a flag, which is a switch that takes an argument
  def flag(*names)
    names = [names].flatten
    verify_unused(names,flags,switches,"in global options")
    flag = Flag.new(names,@@next_desc,@@next_arg_name,@@next_default_value,@@next_long_desc)
    flags[flag.name] = flag
    clear_nexts
  end

  # Create a switch
  def switch(*names)
    names = [names].flatten
    verify_unused(names,flags,switches,"in global options")
    switch = Switch.new(names,@@next_desc,@@next_long_desc)
    switches[switch.name] = switch
    clear_nexts
  end

  # Sets the config file.  If not an absolute path
  # sets the path to the user's home directory
  def config_file(filename)
    if filename =~ /^\//
      @@config_file = filename
    else
      @@config_file = Etc.getpwuid.dir + '/' + filename
    end
    commands[:initconfig] = InitConfig.new(@@config_file)
    @@config_file
  end

  # Define a command.
  def command(*names)
    command = Command.new([names].flatten,@@next_desc,@@next_arg_name,@@next_long_desc)
    commands[command.name] = command
    yield command
    clear_nexts
  end

  # Define a block to run after command line arguments are parsed
  # but before any command is run.  If this block raises an exception
  # the command specified will not be executed.
  # The block will receive the global-options,command,options, and arguments
  # If this block evaluates to true, the program will proceed; otherwise
  # the program will end immediately
  def pre(&a_proc)
    @@pre_block = a_proc
  end

  # Define a block to run after command hase been executed, only
  # if there was not an error.
  # The block will receive the global-options,command,options, and arguments
  def post(&a_proc)
    @@post_block = a_proc
  end

  # Define a block to run if an error occurs.
  # The block will receive any Exception that was caught.
  # It should return false to avoid the built-in error handling (which basically just
  # prints out a message)
  def on_error(&a_proc)
    @@error_block = a_proc
  end

  # Indicate the version of your application
  def version(version)
    @@version = version
  end

  # Call this with "true" will cause the <tt>global_options</tt> and
  # <tt>options</tt> passed to your code to be wrapped in
  # GLI::Option, which is a subclass of OpenStruct that adds
  # <tt>[]</tt> and <tt>[]=</tt> methods.
  def use_openstruct(use_openstruct)
    @@use_openstruct = use_openstruct
  end

  # Runs whatever command is needed based on the arguments. 
  #
  # args - the command line ARGV array
  #
  # Returns a number that would be a reasonable exit code
  def run(args)
    rdoc = RDocCommand.new
    commands[:rdoc] = rdoc if !commands[:rdoc]
    commands[:help] = DefaultHelpCommand.new(@@version,rdoc) if !commands[:help]
    begin
      config = parse_config
      global_options,command,options,arguments = parse_options(args,config)
      copy_options_to_aliased_versions(global_options,command,options)
      proceed = true
      global_options = convert_to_option?(global_options)
      options = convert_to_option?(options)
      proceed = @@pre_block.call(global_options,command,options,arguments) if @@pre_block 
      if proceed
        command = commands[:help] if !command
        command.execute(global_options,options,arguments)
        @@post_block.call(global_options,command,options,arguments) if @@post_block 
      end
      0
    rescue Exception => ex
      regular_error_handling = true
      regular_error_handling = @@error_block.call(ex) if @@error_block

      if regular_error_handling
        $stderr.puts "error: #{ex.message}"
      end

      case ex
      when BadCommandLine: 
        -1
      when CustomExit:
        ex.exit_code
      else 
        -2
      end
    end
  end

  # Simpler means of exiting with a custom exit code.  This will 
  # raise a CustomExit with the given message and exit code, which will ultimatley
  # cause your application to exit with the given exit_code as its exit status
  def exit_now!(message,exit_code)
    raise CustomExit.new(message,exit_code)
  end

  # Possibly returns a copy of the passed-in Hash as an instance of GLI::Option.
  # By default, it will *not*, however by putting <tt>use_openstruct true</tt>
  # in your CLI definition, it will
  def convert_to_option?(options)
    @@use_openstruct ? Options.new(options) : options
  end

  # Copies all options in both global_options and options to keys for the aliases of those flags.
  # For example, if a flag works with either -f or --flag, this will copy the value from [:f] to [:flag]
  # to allow the user to access the options by any alias
  def copy_options_to_aliased_versions(global_options,command,options)
    copy_options_to_aliases(global_options,self)
    copy_options_to_aliases(options,command)
  end

  # For each option in options, copies its value to keys for the aliases of the flags or
  # switches in gli_like
  #
  # options - Hash of options parsed from command line; this is an I/O param
  # gli_like - Object resonding to flags and switches in the same way that GLI or a Command instance do
  def copy_options_to_aliases(options,gli_like)
    new_options = {}
    options.each do |key,value|
      if gli_like.flags[key] && gli_like.flags[key].aliases
        gli_like.flags[key].aliases.each do |alias_name|
          new_options[alias_name] = value
        end
      elsif gli_like.switches[key] && gli_like.switches[key].aliases
        gli_like.switches[key].aliases.each do |alias_name|
          new_options[alias_name] = value
        end
      end
    end
    options.merge!(new_options)
  end

  def parse_config
    return nil if @@config_file.nil?
    require 'yaml'
    if File.exist?(@@config_file)
      File.open(@@config_file) { |f| YAML::load(f) }
    else
      {}
    end
  end

  def program_name(override=nil)
    if override
      @@program_name = override
    end
    @@program_name
  end

  # Returns an array of four values:
  #  * global options (as a Hash)
  #  * Command 
  #  * command options (as a Hash)
  #  * arguments (as an Array)
  def parse_options(args,config=nil)
    command_configs = {}
    if config.nil?
      config = {}
    else
      command_configs = config.delete(GLI::InitConfig::COMMANDS_KEY) if !config.nil?
    end
    global_options,command,options,arguments = parse_options_helper(args.clone,config,nil,Hash.new,Array.new,command_configs)
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
    @@next_long_desc = nil
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
  # [command_configs] the configuration file for all commands, used as defaults
  #
  # This works by finding the first non-switch/flag argument, and taking that sublist and trying to pick out
  # flags and switches.  After this is done, one of the following is true:
  #   * the sublist is empty - in this case, go again, as there might be more flags to parse
  #   * the sublist has a flag left in it - unknown flag; we bail
  #   * the sublist has a non-flag left in it - this is the command (or the start of the arguments list)
  #
  # This sort of does the same thing in two phases; in the first phase, the command hasn't been identified, so
  # we are looking for global switches and flags, ending when we get the command.
  #
  # Once the command has been found, we start looking for command-specific flags and switches.
  # When those have been found, we know the rest of the argument list is arguments for the command
  def parse_options_helper(args,global_options,command,command_options,arguments,command_configs)
    non_flag_i = find_non_flag_index(args)
    all_flags = false
    if non_flag_i == 0
      # no flags
      if !command
        command_name = args.shift
        command = find_command(command_name)
        raise BadCommandLine.new("Unknown command '#{command_name}'") if !command
        return parse_options_helper(args,
                                    global_options,
                                    command,
                                    default_command_options(command,command_configs),
                                    arguments,
                                    command_configs)
      else
        return global_options,command,command_options,arguments + args
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
      # So, there's a case where the first time we request the value for a flag,
      # we get the default and not the user-provided value.  The next time we request
      # it, we want to override it with the real value.
      # HOWEVER, sometimes this happens in reverse, so we want to err on taking the
      # user-provided, non-default value where possible.
      if value 
        if options[name]
          options[name] = value if options[name] == flag.default_value
        else
          options[name] = value
        end
      end
    end

    if try_me.empty?
      return [global_options,command,command_options,arguments] if rest.empty?
      # If we have no more options we've parsed them all
      # and rest may have more
      return parse_options_helper(rest,global_options,command,command_options,arguments,command_configs)
    else
      if command
        check = rest
        check = rest + try_me if all_flags 
        check.each() do |arg| 
          if arg =~ /^\-\-$/
            try_me.delete arg
            break 
          end
          raise BadCommandLine.new("Unknown argument #{arg}") if arg =~ /^\-/ 
        end
        return [global_options,command,command_options,try_me + rest]
      else
        # Now we have our command name
        command_name = try_me.shift
        raise BadCommandLine.new("Unknown argument #{command_name}") if command_name =~ /^\-/

        command = find_command(command_name)
        raise BadCommandLine.new("Unknown command '#{command_name}'") if !command

        return parse_options_helper(rest,
                                    global_options,
                                    command,
                                    default_command_options(command,command_configs),
                                    arguments,
                                    command_configs)
      end
    end

  end

  def default_command_options(command,command_configs)
    options = (command_configs && command_configs[command.name.to_sym]) || {}
  end

  def find_command(name)
    sym = name.to_sym
    return commands[name.to_sym] if commands[sym]
    commands.keys.each do |command_name|
      command = commands[command_name]
      return command if (command.aliases && command.aliases.include?(sym))
    end
    nil
  end

  # Checks that the names passed in have not been used in another flag or option
  def verify_unused(names,flags,switches,context)
    names.each do |name|
      verify_unused_in_option(name,flags,"flag",context)
      verify_unused_in_option(name,switches,"switch",context)
    end
  end

  private

  def verify_unused_in_option(name,option_like,type,context)
    raise ArgumentError.new("#{name} has already been specified as a #{type} #{context}") if option_like[name]
    option_like.each do |one_option_name,one_option|
      if one_option.aliases
        raise ArgumentError.new("#{name} has already been specified as an alias of #{type} #{one_option_name} #{context}") if one_option.aliases.include? name
      end
    end
  end
end
