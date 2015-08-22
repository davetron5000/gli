source 'https://rubygems.org'

gemspec

gem "rcov", ">= 0.9.8", :platforms => :mri_18
gem "simplecov", "~> 0.6.4", :platforms => :mri_19
gem "psych", :platforms => :mri_19

#Travis has an ancient bundler I guess?!?!?  Sigh.
begin
gem "test-unit", :platforms => :mri_22
rescue => ex
  if ex.message =~/mri_22 is not a valid platform/
    if RUBY_VERSION =~ /2\.2\./
      gem 'test-unit'
    end
  else
    raise ex
  end
end

