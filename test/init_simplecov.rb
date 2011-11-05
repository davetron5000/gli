begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test"
  end

  MIN_COVERAGE = 97
  SimpleCov.at_exit do
    if SimpleCov.result.covered_percent < MIN_COVERAGE
      raise "Coverage has dropped below #{MIN_COVERAGE} to #{SimpleCov.result.covered_percent}"
    end
    SimpleCov.result.format!
  end
rescue LoadError
  # Don't care
end
