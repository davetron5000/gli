Feature: The todo app is backwards compatible with legacy subcommand parsing
  As a user of GLI
  My apps with subcommands should support the old, legacy way, by default

  Background:
    Given I have GLI installed
      And GLI's libs are in my path
      And my terminal size is "80x24"
      And todo_legacy's bin directory is in my path

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

  Scenario Outline: Getting Help for a top level command of todo
    # No idea why I have to do this again.
    Given todo_legacy's bin directory is in my path
    When I successfully run `todo <help_invocation>`
    Then the output should contain:
    """
    NAME
        list - List things, such as tasks or contexts

    SYNOPSIS
        todo [global options] list [command options] [tasks] [--flag arg] [-x arg]
        todo [global options] list [command options] contexts [--otherflag arg] [-b] [-f|--foobar]

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


  Scenario: Getting Help for a sub command of todo list
    When I successfully run `todo help list tasks`
    Then the output should contain:
    """
    NAME
        tasks - List tasks

    SYNOPSIS
        todo [global options] list tasks [command options] 
        todo [global options] list tasks [command options] open

    DESCRIPTION
        Lists all of your tasks that you have, in varying orders, and all that
        stuff. Yes, this is long, but I need a long description. 

    COMMAND OPTIONS
        --flag=arg - (default: none)
        -x arg     - blah blah crud x whatever (default: none)
    
    COMMANDS
        <default> - list all tasks
        open      - list open tasks
    """

  Scenario: Getting Help for a sub command with no command options
    When I successfully run `todo help new`
    Then the output should contain:
    """
    NAME
        create - Create a new task or context

    SYNOPSIS
        todo [global options] create 
        todo [global options] create contexts [context_name]
        todo [global options] create tasks task_name[, task_name]*

    COMMANDS
        <default> - Makes a new task
        contexts  - Make a new context
        tasks     - Make a new task
    """
    And the output should not contain "COMMAND OPTIONS"

  Scenario: Running ls w/out subcommand shows help and an error
    When I run `todo ls`
    Then the exit status should not be 0
    And the stderr should contain "error: Command 'ls' requires a subcommand"
    And the stdout should contain:
    """
    NAME
        ls - LS things, such as tasks or contexts

    SYNOPSIS
        todo [global options] ls [command options] contexts [-b] [-f|--foobar]
        todo [global options] ls [command options] tasks [-x arg]

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
