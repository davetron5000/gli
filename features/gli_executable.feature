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
    NAME
        gli - create scaffolding for a GLI-powered application

    SYNOPSIS
        gli [global options] command [command options] [arguments...]

    VERSION
    """
     And the output should contain:
    """
    GLOBAL OPTIONS
        --help         - Show this message
        -n             - Dry run; dont change the disk
        -r, --root=arg - Root dir of project (default: .)
        -v             - Be verbose
        --version      - Display the program version

    COMMANDS
        help           - Shows a list of commands or help for one command
        init, scaffold - Create a new GLI-based project
    """

    Examples:
    |command|
    |       |
    |help   |


  Scenario Outline: Getting help on scaffolding
    When I run `gli help <command>`
    Then the exit status should be 0
     And the output should contain:
    """
    NAME
        init - Create a new GLI-based project

    SYNOPSIS
        gli [global options] init [command options] project_name [command_name][, [command_name]]*

    DESCRIPTION
        This will create a scaffold command line project that uses GLI for command
        line processing. Specifically, this will create an executable ready to go,
        as well as a lib and test directory, all inside the directory named for your
        project 

    COMMAND OPTIONS
        -e, --[no-]ext - Create an ext dir
        --[no-]force   - Overwrite/ignore existing files and directories
        --notest       - Do not create a test or features dir
    """

    Examples:
      |command  |
      |init     |
      |scaffold |


  Scenario: GLI correctly identifies non-existent command
    When I run `gli foobar`
    Then the exit status should not be 0
     And the stderr should contain "error: Unknown command 'foobar'"

  Scenario: GLI correctly identifies non-existent global flag
    When I run `gli -q help`
    Then the exit status should not be 0
     And the stderr should contain "error: Unknown option -q"

  Scenario: GLI correctly identifies non-existent command flag
    When I run `gli init -q`
    Then the exit status should not be 0
     And the stderr should contain "error: Unknown option -q"

  Scenario: The _doc command doesn't blow up
    Given the file "gli.rdoc" doesn't exist
    When I run `gli _doc`
    Then a file named "gli.rdoc" should exist
