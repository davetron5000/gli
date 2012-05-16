Feature: The todo app has a nice user interface
  As a user of the todo application
  It should have a nice UI, since it's GLI-powered

  Background:
    Given I have GLI installed
      And GLI's libs are in my path
      And my terminal size is "80x24"
      And todo's bin directory is in my path

  Scenario: Getting Help for todo in general
    When I successfully run `todo help`
    Then the output should contain:
    """
    NAME
        todo - Manages tasks

    SYNOPSIS
        todo [global options] command [command options] [arguments...]

    VERSION
        0.0.1

    GLOBAL OPTIONS
        --flag=arg         - (default: none)
        --help             - Show this message
        --[no-]otherswitch - 
        --[no-]switch      - 

    COMMANDS
        chained       - 
        chained2, ch2 - 
        create, new   - Create a new task or context
        first         - 
        help          - Shows a list of commands or help for one command
        initconfig    - Initialize the config file using current global options
        list          - List things, such as tasks or contexts
        ls            - LS things, such as tasks or contexts
        second        - 
    """

  Scenario: Getting Help for a top level command of todo
    When I successfully run `todo help list`
    Then the output should contain:
    """
    NAME
        list - List things, such as tasks or contexts

    SYNOPSIS
        todo [global options] list [command options] [--flag arg] [-x arg] [tasks]
        todo [global options] list [command options] [--otherflag arg] [-b] [-f|--foobar] contexts

    DESCRIPTION
        List a whole lot of things that you might be keeping track of in your
        overall todo list.

        This is your go-to place or finding all of the things that you might have
        stored in your todo databases. 

    COMMAND OPTIONS
        -l, --[no-]long - Show long form

    COMMANDS
        contexts - List contexts
        tasks    - List tasks (default)
    """

  Scenario: Getting Help for a sub command of todo list
    When I successfully run `todo help list tasks`
    Then the output should contain:
    """
    NAME
        tasks - List tasks

    SYNOPSIS
        todo [global options] list tasks [command options] 

    DESCRIPTION
        Lists all of your tasks that you have, in varying orders, and all that
        stuff. Yes, this is long, but I need a long description. 

    COMMAND OPTIONS
        --flag=arg - (default: none)
        -x arg     - blah blah crud x whatever (default: none)
    """

  Scenario: Getting Help for a sub command with no command options
    When I successfully run `todo help new`
    Then the output should contain:
    """
    NAME
        create - Create a new task or context

    SYNOPSIS
        todo [global options] create [command options] 
        todo [global options] create [command options]  contexts
        todo [global options] create [command options]  tasks

    COMMANDS
        <default> - Makes a new task
        contexts  - Make a new context
        tasks     - Make a new task
    """
    And the output should not contain "COMMAND OPTIONS"

  Scenario: Running list w/out subcommand performs list tasks by default
    When I successfully run `todo list boo yay`
    Then the output should contain "list tasks: boo,yay"

  Scenario: Running list w/out subcommand or any arguments performs list tasks by default
    When I successfully run `todo list`
    Then the output should contain "list tasks:"

  Scenario: Running chained commands works
    When I successfully run `todo chained foo bar`
    Then the output should contain:
    """
    first: foo,bar
    second: foo,bar
    """

  Scenario: Running chained commands works and is ordered
    When I successfully run `todo chained2 foo bar`
    Then the output should contain:
    """
    second: foo,bar
    first: foo,bar
    """

  Scenario: Running chained commands works and is ordered
    When I successfully run `todo ch2 foo bar`
    Then the output should contain:
    """
    second: foo,bar
    first: foo,bar
    """

  Scenario: Running ls w/out subcommand shows help and an error
    When I run `todo ls`
    Then the exit status should not be 0
    And the stderr should contain "error: Command 'ls' requires a subcommand"
    And the stdout should contain:
    """
    NAME
        ls - LS things, such as tasks or contexts

    SYNOPSIS
        todo [global options] ls [command options] [-b] [-f|--foobar] contexts
        todo [global options] ls [command options] [-x arg] tasks

    DESCRIPTION
        List a whole lot of things that you might be keeping track of in your
        overall todo list.

        This is your go-to place or finding all of the things that you might have
        stored in your todo databases. 

    COMMAND OPTIONS
        -l, --[no-]long - Show long form

    COMMANDS
        contexts - List contexts
        tasks    - List tasks
    """


  Scenario: Init Config makes a reasonable config file
    Given a clean home directory
    When I successfully run `todo --flag foo --switch --no-otherswitch initconfig`
    Then the config file should contain a section for each command and subcommand

  Scenario: Configuration percolates to the app
    Given a clean home directory
    And a config file that specifies defaults for some commands with subcommands
    When I successfully run `todo help list tasks`
    Then I should see the defaults for 'list tasks' from the config file in the help

  Scenario: Do it again because aruba buffers all output
    Given a clean home directory
    And a config file that specifies defaults for some commands with subcommands
    When I successfully run `todo help list contexts`
    Then I should see the defaults for 'list contexts' from the config file in the help
