Given /^"([^"]*)" is in my load path$/ do |path|
  prepend_to_load_path(File.expand_path(File.join(TMP_PATH,path)))
end
