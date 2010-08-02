### Note: the master branch is currently unstable while 1.0 is in beta.<br>The current stable version of bundler is in the branch named `v0.9`.

## Bundler : A gem to bundle gems

Bundler is a tool that manages gem dependencies for your ruby application. It
takes a gem manifest file and is able to fetch, download, and install the gems
and all child dependencies specified in this manifest. It can manage any update
to the gem manifest file and update the bundle's gems accordingly. It also lets
you run any ruby code in context of the bundle's gem environment.

## Installation and usage

See [gembundler.com](http://gembundler.com) for up-to-date installation and usage instructions

## Gem dependency resolution

One of the most important things that the bundler does is do a
dependency resolution on the full list of gems that you specify, all
at once. This differs from the one-at-a-time dependency resolution that
Rubygems does, which can result in the following problem:

    # On my system:
    #   activesupport 3.0.pre
    #   activesupport 2.3.4
    #   activemerchant 1.4.2
    #   rails 2.3.4
    #
    # activemerchant 1.4.2 depends on activesupport >= 2.3.2

    gem "activemerchant", "1.4.2"
    # results in activating activemerchant, as well as
    # activesupport 3.0.pre, since it is >= 2.3.2

    gem "rails", "2.3.4"
    # results in:
    #   can't activate activesupport (= 2.3.4, runtime)
    #   for ["rails-2.3.4"], already activated
    #   activesupport-3.0.pre for ["activemerchant-1.4.2"]

This is because activemerchant has a broader dependency, which results
in the activation of a version of activesupport that does not satisfy
a more narrow dependency.

Bundler solves this problem by evaluating all dependencies at once,
so it can detect that all gems *together* require activesupport "2.3.4".

## Upgrading from Bundler 0.8 to 0.9 and above

Upgrading to Bundler 0.9 from Bundler 0.8 requires upgrading several
API calls in your Gemfile, and some workarounds if you are using Rails 2.3.

### Gemfile Removals

Bundler 0.9 removes the following Bundler 0.8 Gemfile APIs:

1. `disable_system_gems`: This is now the default (and only) option
   for bundler. Bundler uses the system gems you have specified
   in the Gemfile, and only the system gems you have specified
   (and their dependencies)
2. `disable_rubygems`: This is no longer supported. We are looking
   into ways to get the fastest performance out of each supported
   scenario, and we will make speed the default where possible.
3. `clear_sources`: Bundler now defaults to an empty source
   list. If you want to include Rubygems, you can add the source
   via source "http://gemcutter.org". If you use bundle init, this
   source will be automatically added for you in the generated
   Gemfile
4. `bundle_path`: You can specify this setting when installing
   via `bundle install /path/to/bundle`. Bundler will remember
   where you installed the dependencies to on a particular
   machine for future installs, loads, setups, etc.
5. `bin_path`: Bundler no longer generates binaries in the root
   of your app. You should use `bundle exec` to execute binaries
   in the current context.

### Gemfile Changes

Bundler 0.9 changes the following Bundler 0.8 Gemfile APIs:

1. Bundler 0.8 supported :only and :except as APIs for describing
   groups of gems. Bundler 0.9 supports a single `group` method,
   which you can use to group gems together. See the above "Group"
   section for more information.

   This means that `gem "foo", :only => :production` becomes
   `gem "foo", :group => :production`, and
   `only :production { gem "foo" }` becomes
   `group :production { gem "foo" }`

   The short version is: group your gems together logically, and
   use the available commands to make use of the groups you've
   created.

2. `:require_as` becomes `:require`

3. `:vendored_at` is fully removed; you should use `:path`

### API Changes

1. `Bundler.require_env(:environment)` becomes
   `Bundler.require(:multiple, :groups)`. You must
   now specify the default group (the default group is the
   group made up of the gems not assigned to any group)
   explicitly. So `Bundler.require_env(:test)` becomes
   `Bundler.require(:default, :test)`

2. `require 'vendor/gems/environment'`: In unlocked
   mode, where using system gems, this becomes
   `Bundler.setup(:multiple, :groups)`. If you don't
   specify any groups, this puts all groups on the load
   path. In locked, mode, it becomes `require '.bundle/environment'`

## More information

### Development

For information about future plans and changes that will happen between now and bundler 1.0, see the [ROADMAP](http://github.com/carlhuda/bundler/blob/master/ROADMAP.md). To see what has changed in each version of bundler, starting with 0.9.5, see the [CHANGELOG](http://github.com/carlhuda/bundler/blob/master/CHANGELOG.md).

### Deploying to memory-constrained servers

When deploying to a server that is memory-constrained, like Dreamhost, you should run `bundle package` on your local development machine, and then check in the resulting `Gemfile.lock` file and `vendor/cache` directory. The lockfile and cached gems will mean bundler can just install the gems immediately, without contacting any gem servers or using a lot of memory to resolve the dependency tree. On the server, you only need to run `bundle install` after you update your deployed code.

### Other questions

Any remaining questions may be asked via IRC in [#bundler](irc://irc.freenode.net/bundler) on Freenode, or via email on the [Bundler mailing list](http://groups.google.com/group/ruby-bundler).

## Reporting bugs

Before reporting a bug, try these troubleshooting steps:

    rm -rf ~/.bundle/ ~/.gem/ .bundle/ Gemfile.lock
    bundle install

If you are still having problems, please report bugs to the github issue tracker for the project, located at [http://github.com/carlhuda/bundler/issues/](http://github.com/carlhuda/bundler/issues/).

The best possible scenario is a ticket with a fix for the bug and a test for the fix. If that's not possible, instructions to reproduce the issue are vitally important. If you're not sure exactly how to reproduce the issue that you are seeing, create a gist of the following information and include it in your ticket:

  - What version of bundler you are using
  - What version of Ruby you are using
  - Whether you are using RVM, and if so what version
  - Your Gemfile
  - Your Gemfile.lock
  - If you are on 0.9, whether you have locked or not
  - If you are on 1.0, the result of `bundle config`
  - The command you ran to generate exception(s)
  - The exception backtrace(s)

If you are using Rails 2.3, please also include:

  - Your boot.rb file
  - Your preinitializer.rb file
  - Your environment.rb file
