Feature: The scaffold GLI generates works
  As a developer who wants to make a GLI-powered command-line app
  When I generate a GLI-powered app
  Things work out of the box

  Background:
    Given I have GLI installed
      And GLI's libs are in my path
      And my terminal size is "80x24"

  Scenario: Scaffold generates and things look good
    When I run `gli init todo add complete list`
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
    Created ./todo/test/tc_nothing.rb
    Created ./todo/Rakefile
    Created ./todo/Gemfile
    Created ./todo/lib/todo_version.rb

    """
     And the following directories should exist:
       |todo      |
       |todo/bin  |
       |todo/test |
       |todo/lib  |
     And the following files should exist:
       |todo/bin/todo            |
       |todo/README.rdoc         |
       |todo/todo.rdoc           |
       |todo/todo.gemspec        |
       |todo/test/tc_nothing.rb  |
       |todo/Rakefile            |
       |todo/Gemfile             |
       |todo/lib/todo_version.rb |
    When I cd to "todo"
     And I run `bin/todo`
    Then the output should contain:
    """
    usage: todo [global options] command [command options]
    
    Version: 0.0.1
    
    Global Options:
        -f, --flagname=The name of the argument - Describe some flag here (default: 
                                                  the default)
        -s, --switch                            - Describe some switch here
    
    Commands:
        add      - Describe add here
        complete - Describe complete here
        help     - Shows list of commands or help for one command
        list     - Describe list here

    """
    When I run `bin/todo help add`
    Then the output should contain:
    """
    add [command options] Describe arguments to add here
        Describe add here

    Command Options:
        -f arg - Describe a flag to add (default: default)
        -s     - Describe a switch to add
    """
    When I run `rake test`
    Then the output should contain:
    """
    Started
    .
    """
    And the output should contain:
    """

    1 tests, 1 assertions, 0 failures, 0 errors
    """
    When I run `bin/todo rdoc`
    Then the file "todo.rdoc" should contain "todo [global options] command_name [command-specific options] [--] arguments..."
     And the file "todo.rdoc" should contain "[<tt>add</tt>] Describe add here"
     And the file "todo.rdoc" should contain "[<tt>complete</tt>] Describe complete here"
     And the file "todo.rdoc" should contain "[<tt>list</tt>] Describe list here"

      @debug
  Scenario: Scaffold generates and respects flags to create ext dir and avoid test dir
    When I run `gli init -e --notest todo add complete list`
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
    Created ./todo/lib/todo_version.rb

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
       |todo/lib/todo_version.rb |
