Given /^todo_legacy's bin directory is in my path/ do
  add_to_path(File.expand_path(File.join(File.dirname(__FILE__),'..','..','test','apps','todo_legacy','bin')))
end

Given /^todo's bin directory is in my path/ do
  add_to_path(File.expand_path(File.join(File.dirname(__FILE__),'..','..','test','apps','todo','bin')))
end

Given /^the todo app is coded to avoid sorted help commands$/ do
  ENV['TODO_SORT_HELP'] = 'manually'
end

Given /^the todo app is coded to avoid wrapping text$/ do
  ENV['TODO_WRAP_HELP_TEXT'] = 'one_line'
end

Given /^the todo app is coded to wrap text only for tty$/ do
  ENV['TODO_WRAP_HELP_TEXT'] = 'tty_only'
end

Given /^the todo app is coded to hide commands without description$/ do
  ENV['HIDE_COMMANDS_WITHOUT_DESC'] = 'true'
end

Given /^a clean home directory$/ do
  FileUtils.rm_rf File.join(ENV['HOME'],'gli_test_todo.rc')
end

Then /^the config file should contain a section for each command and subcommand$/ do
  config = File.open(File.join(ENV['HOME'],'gli_test_todo.rc')) do |file|
    YAML::load(file)
  end
  expect(config.keys).to include(:flag)
  expect(config[:flag]).to eq('foo')
  config[:flag].tap do |flag|
    if flag.respond_to?(:encoding)
      expect(flag.encoding.name).to eq('UTF-8')
    end
  end
  expect(config.keys).to include(:switch)
  expect(config[:switch]).to eq(true)
  expect(config.keys).to include(:otherswitch)
  expect(config[:otherswitch]).to eq(false)
  expect(config.keys).to include('commands')
  %w(chained chained2 create first list ls second).map(&:to_sym).each do |command_name|
    expect(config['commands'].keys).to include(command_name)
  end
  expect(config['commands'][:create].keys).to include('commands')
  expect(config['commands'][:create]['commands']).to include(:tasks)
  expect(config['commands'][:create]['commands']).to include(:contexts)

  expect(config['commands'][:list].keys).to include('commands')
  expect(config['commands'][:list]['commands']).to include(:tasks)
  expect(config['commands'][:list]['commands']).to include(:contexts)
end

Given /^a config file that specifies defaults for some commands with subcommands$/ do
  @config = {
    'commands' => {
      :list => {
        'commands' => {
          :tasks => {
            :flag => 'foobar',
          },
          :contexts => {
            :otherflag => 'crud',
          },
        }
      }
    }
  }
  File.open(File.join(ENV['HOME'],'gli_test_todo.rc'),'w') do |file|
    file.puts @config.to_yaml
  end
end

Then /^I should see the defaults for '(.*)' from the config file in the help$/ do |command_path|
  if command_path == 'list tasks'
    step %{the output should match /--flag.*default: foobar/}
    expect(unescape(all_output)).not_to match(/#{unescape("--otherflag.*default: crud")}/m)
  elsif command_path == 'list contexts'
    step %{the output should match /--otherflag.*default: crud/}
    expect(unescape(all_output)).not_to match(/#{unescape("--flag.*default: foobar")}/m)
  else
    raise "Don't know how to test for command path #{command_path}"
  end
end


Given /^the todo app is coded to use verbatim formatting$/ do
  ENV['TODO_WRAP_HELP_TEXT'] = 'verbatim'
end

Given(/^my terminal is (\d+) characters wide$/) do |terminal_width|
  ENV['COLUMNS'] = terminal_width.to_s
end

Given(/^my app is configured for "(.*?)" synopses$/) do |synopsis|
  ENV['SYNOPSES'] = synopsis
end
