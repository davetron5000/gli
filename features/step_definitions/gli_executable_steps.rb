Given /^I have GLI installed$/ do
  add_to_lib_path(GLI_LIB_PATH)
end

Given /^my terminal size is "([^"]*)"$/ do |terminal_size|
  if terminal_size =~/^(\d+)x(\d+)$/
    ENV['COLUMNS'] = $1
    ENV['LINES'] = $2
  else
    raise "Terminal size should be COLxLines, e.g. 80x24" 
  end
end


Given /^the file "(.*?)" doesn't exist$/ do |filename|
  FileUtils.rm filename if File.exist?(filename)
end

