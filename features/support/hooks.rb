require 'aruba/cucumber'

Before '@slow-command' do
    @aruba_timeout_seconds = 10
end
