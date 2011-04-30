Given /^I have GLI installed$/ do
end

Given /^my terminal size is "([^"]*)"$/ do |terminal_size|
  if terminal_size =~/^(\d+)x(\d+)$/
    ENV['COLUMNS'] = $1
    ENV['LINES'] = $2
  else
    raise "Terminal size should be COLxLines, e.g. 80x24" 
  end
end

