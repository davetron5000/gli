Contributions are welcome as long as they are part of my vision for GLI (or can be treated as optional to the user).  I am obsessive about backwards-compatibility, so you may need to default things to disable your features.  Sorry, not ready to bump a major version any time soon.

1. Fork my Repository
2. Create a branch off of main
3. Make your changes:
   * Please include tests and watch out for reek and roodi; i.e. keep your code clean
   * If you make changes to the gli executable or the scaffolding, please update the cucumber features
   * Please rubydoc any new methods and update the rubydoc to methods you change in the following format:
```ruby
          # Short description
          #
          # Longer description if needed
          #
          # +args+:: get documented using this syntax
          # +args+:: please state the TYPE of every arg
          #
          # Returns goes here, please state the TYPE of what's returned, if anything
```
   * Use <code># :nodoc:</code> for methods that a _user_ of GLI should not call (but still please do document all methods)
4. Make sure your branch will merge with my gli-2 branch (or just rebase your branch from my gli-2 branch)
5. Create a pull request explaining your change
