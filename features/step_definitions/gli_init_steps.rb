Given /^GLI's libs are in my path$/ do
  ENV['RUBYLIB'] = GLI_LIB_PATH
end

Given /^I make sure todo's lib dir is in my lib path$/ do
  add_to_lib_path("./lib")
end

Given /^todo's libs are no longer in my load path$/ do
  remove_from_lib_path("./lib")
end
