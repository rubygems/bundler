## 0.9.11

  - check now checks installed gems rather than cached gems (#162)
  - don't update the gem index after locking (#169)
  - unknown command line options are now rejected (#163)
  - exec now loads environment.rb if locked (#177)
  - bundle parenthesises arguments for 1.8.6 (#179)
  - show prints the install path if you pass it a gem name (#148)
  - open command to edit an installed gem with $EDITOR (#148)
  - gems can now be assigned to multiple groups without problems (#135, #114)
  - you can pass install the path to the gemfile with --gemfile (#125)
