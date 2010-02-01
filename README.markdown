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
      require File.expand_path('../vendor/environment', __FILE__)
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

## Reporting bugs

Please report all bugs on the github issue tracker for the project located
at:

    http://github.com/wycats/bundler/issues/