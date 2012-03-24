module GLI
  # Things unrelated to the true public interface of Command that are needed for bookkeeping
  # and help support.  Generally, you shouldn't be calling these methods; they are technically public
  # but are essentially part of GLI's internal implementation and subject to change
  module CommandSupport
    # The parent of this command, either the GLI app, or another command
    attr_accessor :parent

    def context_description
      "in the command #{name}"
    end

    # Return true to avoid including this command in your help strings
    def nodoc
      false
    end

    # Return the arguments description
    def arguments_description 
      @arguments_description
    end

    # If true, this command doesn't want the pre block run before it executes
    def skips_pre 
      @skips_pre
    end

    # If true, this command doesn't want the post block run before it executes
    def skips_post 
      @skips_post
    end

    # Return the Array of the command's names
    def names 
      all_forms
    end

    def flag(*names)
      f = if parent.kind_of? Command
            parent.flag(*names)
          else
            super(*names)
          end
      f.associated_command = self
      f
    end

    def switch(*names)
      s = if parent.kind_of? Command
            parent.switch(*names)
          else
            super(*names)
          end
      s.associated_command = self
      s
    end

    def desc(d)
      if parent.kind_of? Command
        parent.desc(d)
      else
        super(d)
      end
    end

    def long_desc(d)
      if parent.kind_of? Command
        parent.long_desc(d)
      else
        super(d)
      end
    end

    def arg_name(d)
      if parent.kind_of? Command
        parent.arg_name(d)
      else
        super(d)
      end
    end

    def default_value(d)
      if parent.kind_of? Command
        parent.default_value(d)
      else
        super(d)
      end
    end

    # Get the usage string
    # CR: This should probably not be here
    def usage 
      usage = name.to_s
      usage += ' [command options]' if !flags.empty? || !switches.empty?
      usage += ' ' + @arguments_description if @arguments_description
      usage
    end

    # Return the flags as a Hash
    def flags 
      @flags ||= {}
    end
    # Return the switches as a Hash
    def switches 
      @switches ||= {}
    end

    def commands # :nodoc:
      @commands ||= {}
    end

    # Executes the command
    def execute(global_options,options,arguments) 
      subcommand,arguments = find_subcommand(arguments)
      if subcommand
        subcommand.execute(global_options,options,arguments)
      else
        get_action(arguments).call(global_options,options,arguments)
      end
    end

    def topmost_ancestor
      c = self
      top = c
      while c.kind_of? self.class
        top = c
        c = c.parent
      end
      top
    end

  private

    def get_action(arguments)
      if @action
        @action
      else
        generate_error_action(arguments)
      end
    end

    def generate_error_action(arguments)
      if am_subcommand?
        if arguments.size > 0
          lambda { |global_options,options,arguments| raise UnknownCommand,"Unknown command '#{arguments[0]}'" }
        else
          lambda { |global_options,options,arguments| raise BadCommandLine,"Command '#{name}' requires a subcommand" }
        end
      elsif have_subcommands?
        lambda { |global_options,options,arguments| raise BadCommandLine,"Command '#{name}' requires a subcommand" }
      else
        lambda { |global_options,options,arguments| raise "Command '#{name}' has no action block" }
      end
    end

    def am_subcommand?
      parent.kind_of?(Command)
    end

    def have_subcommands?
      !self.commands.empty?
    end

    def find_subcommand(arguments)
      subcommand = find_explicit_subcommand(arguments)
      if subcommand
        [subcommand,arguments[1..-1]]
      else
        if !@default_command.nil?
          [find_explicit_subcommand([@default_command.to_s]),arguments]
        else 
          [false,arguments]
        end
      end
    end

    def find_explicit_subcommand(arguments)
      arguments = Array(arguments)
      return false if arguments.empty?
      subcommand_name = arguments.first
      self.commands.values.find { |command|
        [command.name,Array(command.aliases)].flatten.map(&:to_s).any? { |_| _ == subcommand_name }
      }
    end
  end
end
