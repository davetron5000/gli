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

Given /^a clean home directory$/ do
  FileUtils.rm_rf File.join(ENV['HOME'],'gli_test_todo.rc')
end

Then /^the config file should contain a section for each command and subcommand$/ do
  config = File.open(File.join(ENV['HOME'],'gli_test_todo.rc')) do |file|
    YAML::load(file)
  end
  config.keys.should include(:flag)
  config[:flag].should == 'foo'
  config[:flag].tap do |flag|
    if flag.respond_to?(:encoding)
      flag.encoding.name.should == 'UTF-8'
    end
  end
  config.keys.should include(:switch)
  config[:switch].should == true
  config.keys.should include(:otherswitch)
  config[:otherswitch].should == false
  config.keys.should include('commands')
  %w(chained chained2 create first list ls second).map(&:to_sym).each do |command_name|
    config['commands'].keys.should include(command_name)
  end
  config['commands'][:create].keys.should include('commands')
  config['commands'][:create]['commands'].should include(:tasks)
  config['commands'][:create]['commands'].should include(:contexts)

  config['commands'][:list].keys.should include('commands')
  config['commands'][:list]['commands'].should include(:tasks)
  config['commands'][:list]['commands'].should include(:contexts)
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
    unescape(all_output).should_not =~ /#{unescape("--otherflag.*default: crud")}/m
  elsif command_path == 'list contexts'
    step %{the output should match /--otherflag.*default: crud/}
    unescape(all_output).should_not =~ /#{unescape("--flag.*default: foobar")}/m
  else
    raise "Don't know how to test for command path #{command_path}"
  end
end


Given /^the todo app is coded to use verbatim formatting$/ do
  ENV['TODO_WRAP_HELP_TEXT'] = 'verbatim'
end
