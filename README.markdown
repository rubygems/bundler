## Bundler : A gem to bundle gems

    Github:       http://github.com/wycats/bundler
    Mailing list: http://groups.google.com/group/ruby-bundler
    IRC:          #carlhuda on freenode

## Intro

Bundler is a tool that manages gem dependencies for your ruby application. It
takes a gem manifest file and is able to fetch, download, and install the gems
and all child dependencies specified in this manifest. It can manage any update
to the gem manifest file and update the bundle's gems accordingly. It also lets
you run any ruby code in context of the bundle's gem environment.

## Installation

Bundler has no dependencies besides Ruby and RubyGems. Just clone the git
repository and install the gem with the following rake task:

    rake install

You can also install the gem with

    gem install bundler --prerelease

## Usage

The first thing to do is create a gem manifest file named `Gemfile` at the
root directory of your application. This can quickly be done by running
`bundle init` in the directory that you wish the Gemfile to be created in.

### Gemfile

This is where you specify all of your application's dependencies. The
following is an example. For more information, refer to
Bundler::Dsl.

    # Add :gemcutter as a source that Bundler will use
    # to find gems listed in the manifest. At least one source
    # should be listed. URLs maybe also be used, such as
    # http://gems.github.com.
    #
    source :gemcutter

    # Specify a dependency on rails. When bundler downloads gems,
    # it will download rails as well as all of rails' dependencies
    # (such as activerecord, actionpack, etc...)
    #
    # At least one dependency must be specified
    #
    gem "rails"

    # Specify a dependency on rack v.1.0.0. The version is optional.
    # If present, it can be specified the same way as with rubygems'
    # #gem method.
    #
    gem "rack", "1.0.0"

### Groups

Applications may have dependencies that are specific to certain environments,
such as testing or deployment.

You can specify groups of gems in the Gemfile using the following syntax:

    gem "nokogiri", :group => :test

    # or

    group :test do
     gem "webrat"
    end

Note that Bundler adds all the gems without an explicit group name to the
`:default` group.

Groups are involved in a number of scenarios:

1. When installing gems using bundle install, you can choose to leave
   out any group by specifying `--without {group name}`. This can be
   helpful if, for instance, you have a gem that you can only compile
   in certain environments.
2. When setting up load paths using Bundler.setup, Bundler will, by
   default, add the load paths for all groups. You can restrict the
   groups to add by doing `Bundler.setup(:group, :names)`. If you do
   this, you need to specify the `:default` group if you want it
   included.
3. When auto-requiring files using Bundler.require, Bundler will,
   by default, auto-require just the `:default` group. You can specify
   a list of groups to auto-require such as 
   `Bundler.require(:default, :test)`

### Installing gems

Once the manifest file has been created, the next step is to install all
the gems needed to satisfy the Gemfile's dependencies. The `bundle install`
command will do this.

This command will load the Gemfile, resolve all the dependencies, download
all gems that are missing, and install them to the system's RubyGems
repository. Every time an update is made to the Gemfile, run `bundle install`
again to get the new gems installed.

### Locking dependencies

By default, bundler will only ensure that the activated gems satisfy the
Gemfile's dependencies. If you install a newer version of a gem and it
satisfies the dependencies, it will be used instead of the older one.

The command `bundle lock` will lock the bundle to the current set of
resolved gems. This ensures that, until the lock file is removed, that
bundle install and Bundle.setup will always activate the same gems.

### Running the application

Bundler must be required and setup before anything else is required. This
is because it will configure all the load paths and manage rubygems for your.
To do this, include the following at the beginning of your code.

    begin
      # Require the preresolved locked set of gems.
      require File.expand_path('../.bundle/environment', __FILE__)
    rescue LoadError
      # Fallback on doing the resolve at runtime.
      require "rubygems"
      require "bundler"
      Bundler.setup
    end

    # Your application requires come here

The `bundle exec` command provides a way to run arbitrary ruby code in
context of the bundle. For example:

    bundle exec ruby my_ruby_script.rb

To enter a shell that will run all gem executables (such as rake, rails,
etc... ) use `bundle exec bash` (replacing bash for whatever your favorite
shell is).

### Packing the bundle's gems

When sharing or deploying an application, it might be useful to include
everything necessary to install gem dependencies. `bundle pack` will
copy .gem files for all of the bundle's dependencies into vendor/cache.
This way, bundle install can always work no matter what the state of the
remote sources.

## Gem resolution

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

Bundler 0.9 changes a number of APIs in the Gemfile.

### Gemfile Removals

The following Bundler 0.8 APIs are no longer supported:

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
   `Bundler.setup(:multiple, groups)`. If you don't
   specify any groups, this puts all groups on the load
   path. In locked, mode, it becomes `require '.bundle/environment'`

## Reporting bugs

Please report all bugs on the github issue tracker for the project located
at:

    http://github.com/carlhuda/bundler/issues/