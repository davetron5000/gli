require 'simplecov'
SimpleCov.start

MIN_COVERAGE = 96
SimpleCov.at_exit do
  if SimpleCov.result.covered_percent < MIN_COVERAGE
    raise "Coverage has dropped below #{MIN_COVERAGE} to #{SimpleCov.result.covered_percent}"
  end
  SimpleCov.result.format!
end
