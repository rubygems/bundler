# Development setup

Bundler doesn't use a Gemfile to list development dependencies, because when we tried it we couldn't tell if we were awake or it was just another level of dreams. To work on Bundler, you'll probably want to do a couple of things:

1. [Fork the Bundler repo](https://github.com/bundler/bundler), and clone the fork onto your machine. ([Follow this tutorial](https://help.github.com/articles/fork-a-repo/) for instructions on forking a repo.)

2. Install `groff-base` and `graphviz` packages using your package manager, e.g for Ubuntu:

      `$ sudo apt-get install graphviz groff-base -y`

   and for OS X (with brew installed):

      `$ brew install graphviz homebrew/dupes/groff`

3. Install Bundler's development dependencies:

      `$ bin/rake spec:deps`

4. Run the test suite, to make sure things are working:

      `$ bin/rake spec`

5. Set up a shell alias to run Bundler from your clone, e.g. a Bash alias ([follow these instructions](https://www.moncefbelyamani.com/create-aliases-in-bash-profile-to-assign-shortcuts-for-common-terminal-commands/) for adding aliases to your `~/.bashrc` profile):

      `$ alias dbundle='/path/to/bundler/repo/bin/bundle'`

## Debugging with `pry`

To dive into the code with Pry: `RUBYOPT=-rpry dbundle` to require pry and then run commands.
