Feature: The scaffold GLI generates works
  As a developer who wants to make a GLI-powered command-line app
  When I generate a GLI-powered app
  Things work out of the box

  Background:
    Given I have GLI installed
      And GLI's libs are in my path
      And my terminal size is "80x24"

  Scenario: Scaffold generates and things look good
    When I run `gli init --rvmrc todo add complete list`
    Then the exit status should be 0
     And the output should contain exactly:
    """
    Creating dir ./todo/lib...
    Creating dir ./todo/bin...
    Creating dir ./todo/test...
    Created ./todo/bin/todo
    Created ./todo/README.rdoc
    Created ./todo/todo.rdoc
    Created ./todo/todo.gemspec
    Created ./todo/test/default_test.rb
    Created ./todo/test/test_helper.rb
    Created ./todo/Rakefile
    Created ./todo/Gemfile
    Created ./todo/features
    Created ./todo/lib/todo/version.rb
    Created ./todo/lib/todo.rb
    Created ./todo/.rvmrc

    """
     And the following directories should exist:
       |todo      |
       |todo/bin  |
       |todo/test |
       |todo/lib  |
     And the following files should exist:
       |todo/bin/todo              |
       |todo/README.rdoc           |
       |todo/todo.rdoc             |
       |todo/todo.gemspec          |
       |todo/test/default_test.rb  |
       |todo/test/test_helper.rb   |
       |todo/Rakefile              |
       |todo/Gemfile               |
       |todo/lib/todo/version.rb   |
       |todo/lib/todo.rb           |
       |todo/.rvmrc                |
     And the file "todo/README.rdoc" should contain ":include:todo.rdoc"
     And the file "todo/todo.rdoc" should contain "todo _doc"
    When I cd to "todo"
     And I make sure todo's lib dir is in my lib path
     And I run `bin/todo`
    Then the output should contain:
    """
    NAME
        todo - Describe your application here

    SYNOPSIS
        todo [global options] command [command options] [arguments...]
    
    VERSION
        0.0.1
    
    GLOBAL OPTIONS
        -f, --flagname=The name of the argument - Describe some flag here (default:
                                                  the default)
        --help                                  - Show this message
        -s, --[no-]switch                       - Describe some switch here
        --version                               - Display the program version
    
    COMMANDS
        add      - Describe add here
        complete - Describe complete here
        help     - Shows a list of commands or help for one command
        list     - Describe list here

    """
     And I run `bin/todo --help`
    Then the output should contain:
    """
    NAME
        todo - Describe your application here

    SYNOPSIS
        todo [global options] command [command options] [arguments...]
    
    VERSION
        0.0.1
    
    GLOBAL OPTIONS
        -f, --flagname=The name of the argument - Describe some flag here (default:
                                                  the default)
        --help                                  - Show this message
        -s, --[no-]switch                       - Describe some switch here
        --version                               - Display the program version
    
    COMMANDS
        add      - Describe add here
        complete - Describe complete here
        help     - Shows a list of commands or help for one command
        list     - Describe list here

    """
    When I run `bin/todo help add`
    Then the output should contain:
    """
    NAME
        add - Describe add here
    """
    And the output should contain:
    """
    SYNOPSIS
        todo [global options] add [command options] Describe arguments to add here
    """
    And the output should contain:
    """
    COMMAND OPTIONS
        -f arg - Describe a flag to add (default: default)
        -s     - Describe a switch to add
    """
    When I run `rake test`
    Then the output should contain:
    """
    .
    """
    And the output should contain:
    """

    1 tests, 1 assertions, 0 failures, 0 errors
    """
    Given todo's libs are no longer in my load path
    When I run `rake features`
    Then the output should contain:
    """
    1 scenario (1 passed)
    """
    And the output should contain:
    """
    2 steps (2 passed)
    """

  Scenario Outline: Scaffold generates and respects flags to create ext dir and avoid test dir
    When I run `<command>`
    Then the exit status should be 0
     And the output should contain exactly:
    """
    Creating dir ./todo/lib...
    Creating dir ./todo/bin...
    Creating dir ./todo/ext...
    Created ./todo/bin/todo
    Created ./todo/README.rdoc
    Created ./todo/todo.rdoc
    Created ./todo/todo.gemspec
    Created ./todo/Rakefile
    Created ./todo/Gemfile
    Created ./todo/lib/todo/version.rb
    Created ./todo/lib/todo.rb

    """
     And the following directories should exist:
       |todo      |
       |todo/bin  |
       |todo/ext  |
       |todo/lib  |
     And the following directories should not exist:
       |todo/test|
     And the following files should exist:
       |todo/bin/todo            |
       |todo/README.rdoc         |
       |todo/todo.rdoc           |
       |todo/todo.gemspec        |
       |todo/Rakefile            |
       |todo/Gemfile             |
       |todo/lib/todo/version.rb |
       |todo/lib/todo.rb         |

        Examples:
            | command                                     |
            | gli init -e --notest todo add complete list |
            | gli init todo add complete list -e --notest |

  Scenario: Running commands the normal way
    Given I successfully run `gli init todo add complete compute list`
      And I cd to "todo"
      And I make sure todo's lib dir is in my lib path
     When I successfully run `bin/todo add`
     Then the output should contain "add command ran"
     When I successfully run `bin/todo complete`
     Then the output should contain "complete command ran"
     When I run `bin/todo foobar`
     Then the stderr should contain "error: Unknown command 'foobar'"
      And the exit status should not be 0
     
  Scenario: Running commands using short form
    Given I successfully run `gli init todo add complete compute list`
      And I cd to "todo"
      And I make sure todo's lib dir is in my lib path
     When I successfully run `bin/todo a`
     Then the output should contain "add command ran"
     When I successfully run `bin/todo l`
     Then the output should contain "list command ran"
     When I successfully run `bin/todo compl`
     Then the output should contain "complete command ran"
     
  Scenario: Ambiguous commands give helpful output
    Given I successfully run `gli init todo add complete compute list`
      And I cd to "todo"
      And I make sure todo's lib dir is in my lib path
     When I run `bin/todo comp`
     Then the stderr should contain "Ambiguous command 'comp'. It matches complete,compute"
     And the exit status should not be 0
     
  Scenario: Running generated command without bundler gives a helpful error message
    Given I successfully run `gli init todo add complete compute list`
      And I cd to "todo"
     When I run `bin/todo comp`
     Then the exit status should not be 0
     Then the stderr should contain "In development, you need to use `bundle exec bin/todo` to run your app"
     And the stderr should contain "At install-time, RubyGems will make sure lib, etc. are in the load path"
     And the stderr should contain "Feel free to remove this message from bin/todo now"
     
  Scenario: Running commands with a dash in the name
    Given I successfully run `gli init todo-app add complete compute list`
      And I cd to "todo-app"
      And I make sure todo's lib dir is in my lib path
     When I successfully run `bin/todo-app add`
     Then the output should contain "add command ran"
     When I successfully run `bin/todo-app complete`
     Then the output should contain "complete command ran"
     When I run `bin/todo-app foobar`
     Then the stderr should contain "error: Unknown command 'foobar'"
      And the exit status should not be 0
