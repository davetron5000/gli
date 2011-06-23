require 'gli/command.rb'
require 'gli/command_line_token.rb'
require 'gli/copy_options_to_aliases.rb'
require 'gli/exceptions.rb'
require 'gli/flag.rb'
require 'gli/options.rb'
require 'gli/switch.rb'
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
  include CopyOptionsToAliases

  @@program_name = $0.split(/\//)[-1]
  @@post_block = nil
  @@pre_block = nil
  @@error_block = nil
  @@config_file = nil
  @@use_openstruct = false
  @@version = nil
  @@stderr = $stderr
  @@program_desc = nil
  @@skips_pre = false
  @@skips_post = false

  # Override the device of stderr; exposed only for testing
  def error_device=(e) #:nodoc:
    @@stderr = e
  end

  # Reset the GLI module internal data structures; mostly useful for testing
  def reset # :nodoc:
    switches.clear
    flags.clear
    commands.clear
    @@version = nil
    @@config_file = nil
    @@use_openstruct = false
    @@prog_desc = nil
    clear_nexts
  end

  # Describe the next switch, flag, or command.  This should be a
  # short, one-line description
  #
  # +description+:: A String of the short descripiton of the switch, flag, or command following
  def desc(description); @@next_desc = description; end

  # Describe the overall application/programm.  This should be a one-sentence summary
  # of what your program does that will appear in the help output.
  #
  # +description+:: A String of the short description of your program's purpose
  def program_desc(description=nil) 
    if description
      @@program_desc = description
    end
    @@program_desc
  end

  # Use this if the following command should not have the pre block executed.
  # By default, the pre block is executed before each command and can result in
  # aborting the call.  Using this will avoid that behavior for the following command
  def skips_pre
    @@skips_pre = true
  end

  # Use this if the following command should not have the post block executed.
  # By default, the post block is executed after each command.
  # Using this will avoid that behavior for the following command
  def skips_post
    @@skips_post = true
  end

  # Provide a longer, more detailed description.  This
  # will be reformatted and wrapped to fit in the terminal's columns
  #
  # +long_desc+:: A String that is s longer description of the switch, flag, or command following.
  def long_desc(long_desc); @@next_long_desc = long_desc; end

  # Describe the argument name of the next flag.  It's important to keep
  # this VERY short and, ideally, without any spaces (see Example).
  #
  # +name+:: A String that *briefly* describes the argument given to the following command or flag.
  #
  # Example:
  #     desc 'Set the filename'
  #     arg_name 'file_name'
  #     flag [:f,:filename]
  #
  # Produces:
  #     -f, --filename=file_name      Set the filename
  def arg_name(name); @@next_arg_name = name; end

  # set the default value of the next flag
  #
  # +val+:: A String reprensenting the default value to be used for the following flag if the user doesn't specify one
  #         and, when using a config file, the config also doesn't specify one
  def default_value(val); @@next_default_value = val; end

  # Create a flag, which is a switch that takes an argument
  #
  # +names+:: a String or Symbol, or an Array of String or Symbol that represent all the different names
  #           and aliases for this flag.
  #
  # Example:
  #
  #     desc 'Set the filename'
  #     flag [:f,:filename,'file-name']
  #
  # Produces:
  #
  #     -f, --filename, --file-name=arg     Set the filename
  def flag(*names)
    names = [names].flatten
    verify_unused(names,flags,switches,"in global options")
    flag = Flag.new(names,@@next_desc,@@next_arg_name,@@next_default_value,@@next_long_desc)
    flags[flag.name] = flag
    clear_nexts
  end

  # Create a switch, which is a command line flag that takes no arguments (thus, it _switches_ something on)
  #
  # +names+:: a String or Symbol, or an Array of String or Symbol that represent all the different names
  #           and aliases for this switch.
  def switch(*names)
    names = [names].flatten
    verify_unused(names,flags,switches,"in global options")
    switch = Switch.new(names,@@next_desc,@@next_long_desc)
    switches[switch.name] = switch
    clear_nexts
  end

  # Sets that this app uses a config file as well as the name of the config file.  
  #
  # +filename+:: A String representing the path to the file to use for the config file.  If it's an absolute
  #              path, this is treated as the path to the file.  If it's *not*, it's treated as relative to the user's home
  #              directory as produced by <code>Etc.getpwuid.dir</code>.
  def config_file(filename)
    if filename =~ /^\//
      @@config_file = filename
    else
      @@config_file = Etc.getpwuid.dir + '/' + filename
    end
    commands[:initconfig] = InitConfig.new(@@config_file)
    @@config_file
  end

  # Define a new command.  This takes a block that will be given an instance of the Command that was created.
  # You then may call methods on this object to define aspects of that Command.
  #
  # +names+:: a String or Symbol, or an Array of String or Symbol that represent all the different names and aliases for this command.
  #
  def command(*names)
    command = Command.new([names].flatten,@@next_desc,@@next_arg_name,@@next_long_desc,@@skips_pre,@@skips_post)
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

  # Define a block to run after the command was executed, <b>only
  # if there was not an error</b>.
  # The block will receive the global-options,command,options, and arguments
  def post(&a_proc)
    @@post_block = a_proc
  end

  # Define a block to run if an error occurs.
  # The block will receive any Exception that was caught.
  # It should evaluate to false to avoid the built-in error handling (which basically just
  # prints out a message). GLI uses a variety of exceptions that you can use to find out what 
  # errors might've occurred during command-line parsing:
  # * GLI::CustomExit
  # * GLI::UnknownCommandArgument
  # * GLI::UnknownGlobalArgument
  # * GLI::UnknownCommand
  # * GLI::BadCommandLine
  def on_error(&a_proc)
    @@error_block = a_proc
  end

  # Indicate the version of your application
  #
  # +version+:: String containing the version of your application.  
  def version(version)
    @@version = version
  end

  # Call this with +true+ will cause the +global_options+ and
  # +options+ passed to your code to be wrapped in
  # Options, which is a subclass of +OpenStruct+ that adds
  # <tt>[]</tt> and <tt>[]=</tt> methods.
  #
  # +use_openstruct+:: a Boolean indicating if we should use OpenStruct instead of Hashes
  def use_openstruct(use_openstruct)
    @@use_openstruct = use_openstruct
  end

  # Runs whatever command is needed based on the arguments. 
  #
  # +args+:: the command line ARGV array
  #
  # Returns a number that would be a reasonable exit code
  def run(args) #:nodoc:
    rdoc = RDocCommand.new
    commands[:rdoc] = rdoc if !commands[:rdoc]
    commands[:help] = DefaultHelpCommand.new(@@version,rdoc) if !commands[:help]
    exit_code = 0
    begin
      config = parse_config
      override_defaults_based_on_config(config)
      global_options,command,options,arguments = parse_options(args)
      copy_options_to_aliased_versions(global_options,command,options)
      global_options = convert_to_openstruct?(global_options)
      options = convert_to_openstruct?(options)
      if proceed?(global_options,command,options,arguments)
        command = commands[:help] if !command
        command.execute(global_options,options,arguments)
        if !command.skips_post && @@post_block
          @@post_block.call(global_options,command,options,arguments)
        end
      end
    rescue Exception => ex

      @@stderr.puts error_message(ex) if regular_error_handling?(ex)

      exit_code = if ex.respond_to? :exit_code
        ex.exit_code
      else
        -2
      end
      raise ex if ENV['GLI_DEBUG'] == 'true'
    end
    exit_code
  end

  # True if we should proceed with executing the command; this calls
  # the pre block if it's defined
  def proceed?(global_options,command,options,arguments) #:nodoc:
    if command && command.skips_pre
      true
    elsif @@pre_block 
      @@pre_block.call(global_options,command,options,arguments) 
    else
      true
    end
  end

  # Returns true if we should proceed with GLI's basic error handling.
  # This calls the error block if the user provided one
  def regular_error_handling?(ex) #:nodoc:
    if @@error_block
      @@error_block.call(ex)
    else
      true
    end
  end

  # Returns a String of the error message to show the user
  # +ex+:: The exception we caught that launched the error handling routines
  def error_message(ex) #:nodoc:
    msg = "error: #{ex.message}"
    case ex
    when UnknownCommand
      msg += ". Use '#{program_name} help' for a list of commands"
    when UnknownCommandArgument
      msg += ". Use '#{program_name} help #{ex.command.name}' for a list of command options"
    when UnknownGlobalArgument
      msg += ". Use '#{program_name} help' for a list of global options"
    end
  end

  # Simpler means of exiting with a custom exit code.  This will 
  # raise a CustomExit with the given message and exit code, which will ultimatley
  # cause your application to exit with the given exit_code as its exit status
  def exit_now!(message,exit_code)
    raise CustomExit.new(message,exit_code)
  end

  # Set or get the name of the program, if you don't want the default (which is
  # the name of the command line program).  This
  # is only used currently in the help and rdoc commands.
  #
  # +override+:: A String that represents the name of the program to use, other than the default.
  #
  # Returns the current program name, as a String
  def program_name(override=nil)
    if override
      @@program_name = override
    end
    @@program_name
  end

  alias :d :desc
  alias :f :flag
  alias :s :switch
  alias :c :command

  # Possibly returns a copy of the passed-in Hash as an instance of GLI::Option.
  # By default, it will *not*. However by putting <tt>use_openstruct true</tt>
  # in your CLI definition, it will
  def convert_to_openstruct?(options) # :nodoc:
    @@use_openstruct ? Options.new(options) : options
  end

  # Copies all options in both global_options and options to keys for the aliases of those flags.
  # For example, if a flag works with either -f or --flag, this will copy the value from [:f] to [:flag]
  # to allow the user to access the options by any alias
  def copy_options_to_aliased_versions(global_options,command,options) # :nodoc:
    copy_options_to_aliases(global_options)
    command.copy_options_to_aliases(options)
  end

  def parse_config # :nodoc:
    return nil if @@config_file.nil?
    require 'yaml'
    if File.exist?(@@config_file)
      File.open(@@config_file) { |file| YAML::load(file) }
    else
      {}
    end
  end

  # Returns an array of four values:
  #  * global options (as a Hash)
  #  * Command 
  #  * command options (as a Hash)
  #  * arguments (as an Array)
  def parse_options(args) # :nodoc:
    global_options,command,options,arguments = parse_options_helper(args.clone,Hash.new,nil,Hash.new,Array.new)
    flags.each { |name,flag| global_options[name] = flag.default_value if !global_options[name] }
    command.flags.each { |name,flag| options[name] = flag.default_value if !options[name] }
    return [global_options,command,options,arguments]
  end

  # Finds the index of the first non-flag
  # argument or -1 if there wasn't one.
  def find_non_flag_index(args) # :nodoc:
    args.each_with_index do |item,index|
      return index if item =~ /^[^\-]/
      return index-1 if item =~ /^\-\-$/
    end
    -1
  end

  def flag_switch_index(args)
    args.each_with_index do |item,index|
      return index if item =~ /^[\-]/
    end
    -1
  end

  def clear_nexts # :nodoc:
    @@next_desc = nil
    @@next_arg_name = nil
    @@next_default_value = nil
    @@next_long_desc = nil
    @@skips_pre = false
    @@skips_post = false
  end

  clear_nexts

  def flags # :nodoc:
    @@flags ||= {}
  end
  def switches # :nodoc:
    @@switches ||= {}
  end
  def commands # :nodoc:
    @@commands ||= {}
  end

  # Recursive helper for parsing command line options
  # <code>args</code>:: the arguments that have yet to be processed
  # <code>global_options</code>:: the global options hash
  # <code>command</code>:: the Command that has been identified (or nil if not identified yet)
  # <code>command_options</code>:: options for Command
  # <code>arguments</code>:: the arguments for Command
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
  def parse_options_helper(args,global_options,command,command_options,arguments) # :nodoc:
    non_flag_i = find_non_flag_index(args)
    all_flags = false
    if non_flag_i == 0
      # no flags
      if !command
        command_name = args.shift
        command = find_command(command_name)
        raise UnknownCommand.new("Unknown command '#{command_name}'") if !command
        return parse_options_helper(args,
                                    global_options,
                                    command,
                                    Hash.new,
                                    arguments)
      elsif((index = flag_switch_index(args)) >= 0)
        try_me = args[0..index-1]
        rest = args[index..args.length]
        new_args = rest + try_me
        return parse_options_helper(new_args,
                                    global_options,
                                    command,
                                    Hash.new,
                                    arguments)
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
      return parse_options_helper(rest,global_options,command,command_options,arguments)
    else
      if command
        check = rest
        check = rest + try_me if all_flags 
        check.each() do |arg| 
          if arg =~ /^\-\-$/
            try_me.delete arg
            break 
          end
          raise UnknownCommandArgument.new("Unknown option #{arg}",command) if arg =~ /^\-/ 
        end
        return [global_options,command,command_options,try_me + rest]
      else
        # Now we have our command name
        command_name = try_me.shift
        raise UnknownGlobalArgument.new("Unknown option #{command_name}") if command_name =~ /^\-/

        command = find_command(command_name)
        raise UnknownCommand.new("Unknown command '#{command_name}'") if !command

        return parse_options_helper(rest,
                                    global_options,
                                    command,
                                    Hash.new,
                                    arguments)
      end
    end
  end

  def find_command(name) # :nodoc:
    sym = name.to_sym
    return commands[name.to_sym] if commands[sym]
    commands.each do |command_name,command|
      return command if (command.aliases && command.aliases.include?(sym))
    end
    nil
  end

  # Checks that the names passed in have not been used in another flag or option
  def verify_unused(names,flags,switches,context) # :nodoc:
    names.each do |name|
      verify_unused_in_option(name,flags,"flag",context)
      verify_unused_in_option(name,switches,"switch",context)
    end
  end

  private

  def verify_unused_in_option(name,option_like,type,context) # :nodoc:
    raise ArgumentError.new("#{name} has already been specified as a #{type} #{context}") if option_like[name]
    option_like.each do |one_option_name,one_option|
      if one_option.aliases
        raise ArgumentError.new("#{name} has already been specified as an alias of #{type} #{one_option_name} #{context}") if one_option.aliases.include? name
      end
    end
  end

  # Sets the default values for flags based on the configuration
  def override_defaults_based_on_config(config)
    config ||= {}
    config['commands'] ||= {}

    override_default(flags,config)
    override_default(switches,config)

    commands.each do |command_name,command|
      command_config = config['commands'][command_name] || {}

      override_default(command.flags,command_config)
      override_default(command.switches,command_config)
    end
  end

  def override_default(tokens,config)
    tokens.each do |name,token|
      token.default_value=config[name] if config[name]
    end
  end

end
