echo tests
rvm 1.9.2@gli-dev,1.9.3@gli-dev,1.8.7@gli-dev,jruby@gli-dev,rbx@gli-dev,ree@gli-dev --yaml rake test | bin/report_on_rake_results
rake clobber > /dev/null 2>&1
echo features
rvm 1.9.2@gli-dev,1.9.3@gli-dev,1.8.7@gli-dev,jruby@gli-dev,rbx@gli-dev,ree@gli-dev --yaml rake features | bin/report_on_rake_results
rake clobber > /dev/null 2>&1
