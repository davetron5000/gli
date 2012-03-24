Given /^todo's bin directory is in my path/ do
  add_to_path(File.expand_path(File.join(File.dirname(__FILE__),'..','..','test','apps','todo','bin')))
end

