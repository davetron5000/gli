Feature: The scaffold GLI generates works
  As a developer who wants to make a GLI-powered command-line app
  When I generate a GLI-powered app
  Things work out of the box

  Background:
    Given I am in a clean gemset
      And I have the local GLI gem installed
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
    When I cd to "todo"
     And I run `bin/todo`
    Then the output should contain exactly:
    """
    foo

    """


