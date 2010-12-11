module GLI
  # Class to encapsulate stuff about the terminal.  This is a singleton, mostly to facilitate testing.
  class Terminal

    @@default_size = [80,24]

    # Get the default size of the terminal when we can't figure it out
    # 
    # Returns an array of int [cols,rows]
    def self.default_size
      @@default_size
    end

    # Set the default size of the terminal to use when we can't figure it out
    #
    # size - array of two int [cols,rows]
    def self.default_size=(size)
      @@default_size = size
    end

    @@instance = Terminal.new
    # Provide access to the shared instance
    def self.instance; @@instance; end

    @unsafe = false

    def make_unsafe!;
      @unsafe = true
    end

    # Returns true if the given command exists on this system
    #
    # command - The command to check for
    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
    end

    # Ripped from hirb https://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb
    # Returns an array of size two ints representing the terminal width and height
    def size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif (jruby? || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
        [run_command('tput cols').to_i, run_command('tput lines').to_i]
      elsif STDIN.tty? && command_exists?('stty')
        run_command('stty size').scan(/\d+/).map { |s| s.to_i }.reverse
      else
        Terminal.default_size
      end
    rescue Exception => ex
      raise ex if @unsafe
      Terminal.default_size
    end

    # Runs a command using backticks.  Extracted to allow for testing
    def run_command(command)
      `#{command}`
    end

    # True if we are JRuby; exposed to allow for testing
    def jruby?; RUBY_PLATFORM =~ /java/; end

  end
end
