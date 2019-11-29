# Development setup

Bundler doesn't use a Gemfile to list development dependencies, because when we tried it we couldn't tell if we were awake or it was just another level of dreams. To work on Bundler, you'll probably want to do a couple of things:

1. [Fork the Bundler repo](https://github.com/bundler/bundler), and clone the fork onto your machine. ([Follow this tutorial](https://help.github.com/articles/fork-a-repo/) for instructions on forking a repo.)

2. Install `groff-base` and `graphviz` packages using your package manager:

        $ sudo apt-get install graphviz groff-base -y

    And for OS X (with brew installed):

        $ brew install graphviz groff

3. You may also have to install the `bsdmainutils` package on linux if your distribution does not include the `col` command.

        $ sudo apt-get install bsdmainutils -y

4. Install Bundler's development dependencies:

        $ bin/rake spec:deps

5. Run the test suite, to make sure things are working:

        $ bin/rake spec

6. Optionally, you can run the test suite in parallel:

        $ bin/parallel_rspec spec

6. Set up a shell alias to run Bundler from your clone, e.g. a Bash alias ([follow these instructions](https://www.moncefbelyamani.com/create-aliases-in-bash-profile-to-assign-shortcuts-for-common-terminal-commands/) for adding aliases to your `~/.bashrc` profile):

        $ alias dbundle='/path/to/bundler/repo/bin/bundle'

## Debugging with `pry`

To dive into the code with Pry: `RUBYOPT=-rpry dbundle` to require pry and then run commands.

For background context: you can manipulate environment variables in Ruby to control the Ruby interpreter's behavior. Ruby uses the `RUBYOPT` environment variable to specify options to launch Ruby with.

The arguments of `RUBYOPT` are applied as if you had typed them as flags after `ruby`. The `-r` flag means 'require'. So saying `-rpry` means `require 'pry'`. To illustrate, `ruby -rpry /path/to/bundle` is the same as `RUBYOPT=-rpry ruby /path/to/bundle`.

So, `RUBYOPT=-rpry dbundle` is saying "require pry and require this path to Bundler", which means that you will start your development environment with `pry` and your local bundler.

_Why is this necessary?_ Why isn't `require 'pry'; binding.pry` enough?

The reason for combining `RUBYOPT` with `dbundle` is because Bundler takes over what gems are available. If you have `pry` installed on your machine but not included in the Gemfile, Bundler itself will remove `pry` from the list of gems you can require. Setting `RUBYOPT=-rpry` is a way to require `pry` before Bundler takes over and removes it from the list of gems that can be required. That way, later, you can take advantage of `binding.pry` and have it work.
Unfortunately, if you waited until the point of `binding.pry` to `require 'pry'`, it would fail anytime `pry` is not in the Gemfile.
