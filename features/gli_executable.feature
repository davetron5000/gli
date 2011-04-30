Feature: The GLI executable works as intended
  As a developer who wants to make a GLI-powered command-line app
  When I use the app provided by GLI
  I get a reasonably working application

  Background:
    Given I have GLI installed
      And my terminal size is "80x24"

  Scenario Outline: Getting Help for GLI
    When I run `gli <command>`
    Then the exit status should be 0
     And the output should contain:
    """
    usage: gli [global options] command [command options]

    Version:
    """
     And the output should contain:
    """
    Global Options:
        -n             - Dry run; dont change the disk
        -r, --root=arg - Root dir of project (default: .)
        -v             - Be verbose

    Commands:
        help           - Shows list of commands or help for one command
        init, scaffold - Create a new GLI-based project
    """

    Examples:
    |command|
    |       |
    |help   |


  Scenario Outline: Getting help on scaffolding
    When I run `gli help <command>`
    Then the exit status should be 0
     And the output should contain exactly:
    """
    init [command options] project_name [command[ command]*]
        Create a new GLI-based project

        This will create a scaffold command line project that uses GLI for command 
        line processing. Specifically, this will create an executable ready to go, as
        well as a lib and test directory, all inside the directory named for your
        project

    Command Options:
        -e, --ext - Create an ext dir
        --force   - Overwrite/ignore existing files and directories
        --notest  - Do not create a test dir

    """

    Examples:
      |command  |
      |init     |
      |scaffold |


  Scenario: GLI correctly identifies non-existent command
    When I run `gli foobar`
    Then the exit status should not be 0
     And the output should contain exactly:
     """
     error: Unknown command 'foobar'. Use 'gli help' for a list of commands

     """

  Scenario: GLI correctly identifies non-existent global flag
    When I run `gli -q help`
    Then the exit status should not be 0
     And the output should contain exactly:
     """
     error: Unknown option -q. Use 'gli help' for a list of global options

     """

  Scenario: GLI correctly identifies non-existent command flag
    When I run `gli init -q`
    Then the exit status should not be 0
     And the output should contain exactly:
     """
     error: Unknown option -q. Use 'gli help init' for a list of command options

     """
