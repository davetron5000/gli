class FakeStdOut
  attr_reader :strings
  def puts(string=nil)
    @strings ||= []
    @strings << string unless string.nil?
  end

  # Returns true if the regexp matches anything in the output
  def contained?(regexp)
    strings.find{ |x| x =~ regexp }
  end

  def to_s
    @strings.join("\n")
  end
end
