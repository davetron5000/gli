require 'gli'
require 'gli/command'
require 'yaml'

module GLI
  class InitConfig < Command # :nodoc:
    COMMANDS_KEY = 'commands'

    def initialize(config_file_name,commands,flags,switches)
      @filename = config_file_name
      super(:names => :initconfig,
            :description => "Initialize the config file using current global options",
            :long_desc => 'Initializes a configuration file where you can set default options for command line flags, both globally and on a per-command basis.  These defaults override the built-in defaults and allow you to omit commonly-used command line flags when invoking this program')

      self.desc 'force overwrite of existing config file'
      self.switch :force

      @commands = commands
      @flags = flags
      @switches = switches
    end

    def execute(global_options,options,arguments)
      if options[:force] || !File.exist?(@filename)
        create_config(global_options,options,arguments)
      else
        raise "Not overwriting existing config file #{@filename}, use --force to override"
      end
    end

  private

    def create_config(global_options,options,arguments)
      config = Hash[global_options.map { |k,v|
        if v.kind_of?(String) && v.respond_to?(:force_encoding)
          [k,v.force_encoding("utf-8")]
        else
          [k,v]
        end
      }]
      config[COMMANDS_KEY] = {}
      @commands.each do |name,command|
        if (command != self) && (name != :rdoc) && (name != :help)
          if command != self
            config[COMMANDS_KEY][name.to_sym] = config_for_command(@commands,name.to_sym)
          end
        end
      end
      File.open(@filename,'w', 0600) do |file|
        YAML.dump(config,file)
      end
    end

    def config_for_command(commands,command_name)
      {}.tap do |hash|
        subcommands = commands[command_name].commands
        subcommands.each do |name,subcommand|
          next unless name.kind_of? Symbol
          hash[COMMANDS_KEY] ||= {}
          puts "#{command_name}:#{name}"
          hash[COMMANDS_KEY][name.to_sym] = config_for_command(subcommands,name)
        end
      end
    end
  end
end
