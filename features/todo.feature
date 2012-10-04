Feature: The todo app has a nice user interface
  As a user of the todo application
  It should have a nice UI, since it's GLI-powered

  Background:
    Given I have GLI installed
      And GLI's libs are in my path
      And my terminal size is "80x24"
      And todo's bin directory is in my path

  Scenario Outline: Getting Help for todo in general
    When I successfully run `todo <help>`
    Then the output should contain:
    """
    NAME
        todo - Manages tasks

        A test program that has a sophisticated UI that can be used to exercise a
        lot of GLI's power

    SYNOPSIS
        todo [global options] command [command options] [arguments...]

    VERSION
        0.0.1

    GLOBAL OPTIONS
        --flag=arg         - (default: none)
        --help             - Show this message
        --[no-]otherswitch - 
        --[no-]switch      - 
        --version          - 

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
        third         - 
    """
    Examples:
      | help      |
      | help      |
      | --version |

  Scenario: Help completion mode
    When I successfully run `todo help -c`
    Then the output should contain:
    """
    ch2
    chained
    chained2
    create
    first
    help
    initconfig
    list
    ls
    new
    second
    """

  Scenario: Help completion mode for partial match
    When I successfully run `todo help -c ch`
    Then the output should contain:
    """
    ch2
    chained
    chained2
    """

  Scenario: Help completion mode for subcommands
    When I successfully run `todo help -c list`
    Then the output should contain:
    """
    contexts
    tasks
    """

  Scenario: Help completion mode partial match for subcommands
    When I successfully run `todo help -c list con`
    Then the output should contain:
    """
    contexts
    """

  Scenario: Getting Help with self-ordered commands
    Given the todo app is coded to avoid sorted help commands
    When I successfully run `todo help`
    Then the output should contain:
    """
    NAME
        todo - Manages tasks

        A test program that has a sophisticated UI that can be used to exercise a
        lot of GLI's power

    SYNOPSIS
        todo [global options] command [command options] [arguments...]

    VERSION
        0.0.1

    GLOBAL OPTIONS
        --flag=arg         - (default: none)
        --help             - Show this message
        --[no-]otherswitch - 
        --[no-]switch      - 
        --version          - 

    COMMANDS
        help          - Shows a list of commands or help for one command
        initconfig    - Initialize the config file using current global options
        create, new   - Create a new task or context
        list          - List things, such as tasks or contexts
        ls            - LS things, such as tasks or contexts
        third         - 
        first         - 
        second        - 
        chained       - 
        chained2, ch2 - 
    """

  Scenario Outline: Getting Help for a top level command of todo
    When I successfully run `todo <help_invocation>`
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

    Examples:
      | help_invocation |
      | help list       |
      | list -h         |
      | list --help     |


  Scenario: Getting Help with no wrapping
    Given the todo app is coded to avoid wrapping text
    When I successfully run `todo help list`
    Then the output should contain:
    """
    NAME
        list - List things, such as tasks or contexts

    SYNOPSIS
        todo [global options] list [command options] [--flag arg] [-x arg] [tasks]
        todo [global options] list [command options] [--otherflag arg] [-b] [-f|--foobar] contexts

    DESCRIPTION
        List a whole lot of things that you might be keeping track of    in your overall todo list.   This is your go-to place or finding all of the things that you   might have    stored in    your todo databases. 

    COMMAND OPTIONS
        -l, --[no-]long - Show long form

    COMMANDS
        contexts - List contexts
        tasks    - List tasks (default)
    """

  Scenario: Getting Help with verbatim formatting
    Given the todo app is coded to use verbatim formatting
    When I successfully run `todo help list`
    Then the output should contain:
    """
    NAME
        list - List things, such as tasks or contexts

    SYNOPSIS
        todo [global options] list [command options] [--flag arg] [-x arg] [tasks]
        todo [global options] list [command options] [--otherflag arg] [-b] [-f|--foobar] contexts

    DESCRIPTION
        
      List a whole lot of things that you might be keeping track of 
      in your overall todo list.
    
      This is your go-to place or finding all of the things that you
      might have 
      stored in 
      your todo databases.
     

    COMMAND OPTIONS
        -l, --[no-]long - Show long form

    COMMANDS
        contexts - List contexts
        tasks    - List tasks (default)
    """

  Scenario: Getting Help without wrapping
    Given the todo app is coded to wrap text only for tty
    When I successfully run `todo help list`
    Then the output should contain:
    """
    NAME
        list - List things, such as tasks or contexts

    SYNOPSIS
        todo [global options] list [command options] [--flag arg] [-x arg] [tasks]
        todo [global options] list [command options] [--otherflag arg] [-b] [-f|--foobar] contexts

    DESCRIPTION
        List a whole lot of things that you might be keeping track of    in your overall todo list.   This is your go-to place or finding all of the things that you   might have    stored in    your todo databases. 

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
        todo [global options] create [command options]  contexts [context_name]
        todo [global options] create [command options]  tasks task_name[, task_name]*

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

  Scenario: Init Config makes a reasonable config file if one is there and we force it
    Given a clean home directory
    And I successfully run `todo --flag foo --switch --no-otherswitch initconfig`
    When I run `todo --flag foo --switch --no-otherswitch initconfig`
    Then the exit status should not be 0
    When I run `todo --flag foo --switch --no-otherswitch initconfig --force`
    Then the exit status should be 0

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
