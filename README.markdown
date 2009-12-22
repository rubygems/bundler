## Bundler : A gem to bundle gems

    Github:       http://github.com/wycats/bundler
    Mailing list: http://groups.google.com/group/ruby-bundler
    IRC:          #carlhuda on freenode

## Intro

Bundler is a tool that manages gem dependencies for your ruby application. It
takes a gem manifest file and is able to fetch, download, and install the gems
and all child dependencies specified in this manifest. It can manage any update
to the gem manifest file and update the bundled gems accordingly. It also lets
you run any ruby code in context of the bundled gem environment.

## Installation

Bundler has no dependencies. Just clone the git repository and install the gem
with the following rake task:

    rake install

You can also install the gem with

    gem install bundler

## Usage

Bundler requires a gem manifest file to be created. This should be a file named
`Gemfile` located in the root directory of your application. After the manifest
has been created, in your shell, cd into your application's directory and run
`gem bundle`. This will start the bundling process.

### Manifest file

This is where you specify all of your application's dependencies. By default
this should be in a file named `Gemfile` located in your application's root
directory. The following is an example of a potential `Gemfile`. For more
information, please refer to Bundler::ManifestBuilder.

    # Specify a dependency on rails. When the bundler downloads gems,
    # it will download rails as well as all of rails' dependencies (such as
    # activerecord, actionpack, etc...)
    #
    # At least one dependency must be specified
    gem "rails"

    # Specify a dependency on rack v.1.0.0. The version is optional. If present,
    # it can be specified the same way as with rubygems' #gem method.
    gem "rack", "1.0.0"

    # Specify a dependency rspec, but only require that gem in the "testing"
    # environment. :except is also a valid option to specify environment
    # restrictions.
    gem "rspec", :only => :testing

    # Specify a dependency, but specify that it is already present and expanded
    # at vendor/rspec. Bundler will treat rspec as though it was the rspec gem
    # for the purpose of gem resolution: if another gem depends on a version
    # of rspec satisfied by "1.1.6", it will be used.
    #
    # If a gemspec is found in the directory, it will be used to specify load
    # paths and supply additional dependencies.
    #
    # Bundler will also recursively search for *.gemspec, and assume that
    # gemspecs it finds represent gems that are rooted in the same directory
    # the gemspec is found in.
    gem "rspec", "1.1.6", :vendored_at => "vendor/rspec"

    # You can also control what will happen when you run Bundler.require_env
    # by using the :require_as option, as per the next two examples.

    # Don't auto-require this gem.
    gem "rspec-rails", "1.2.9", :require_as => nil

    # Require something other than the default.
    gem "yajl-ruby", "0.6.7", :require_as => "yajl/json_gem"

    # Works exactly like :vendored_at, but first downloads the repo from
    # git and handles stashing the files for you. As with :vendored_at,
    # Bundler will automatically use *.gemspec files in the root or anywhere
    # in the repository.
    gem "rails", "3.0.pre", :git => "git://github.com/rails/rails.git"

    # Add http://gems.github.com as a source that the bundler will use
    # to find gems listed in the manifest. By default,
    # http://gems.rubyforge.org is already added to the list.
    #
    # This is an optional setting.
    source "http://gems.github.com"

    # Specify where the bundled gems should be stashed. This directory will
    # be a gem repository where all gems are downloaded to and installed to.
    #
    # This is an optional setting.
    # The default is: vendor/gems
    bundle_path "my/bundled/gems"

    # Specify where gem executables should be copied to.
    #
    # This is an optional setting.
    # The default is: bin
    bin_path "my/executables"

    # Specify that rubygems should be completely disabled. This means that it
    # will be impossible to require it and that available gems will be
    # limited exclusively to gems that have been bundled.
    #
    # The default is to automatically require rubygems. There is also a
    # `disable_system_gems` option that will limit available rubygems to
    # the ones that have been bundled.
    disable_rubygems

### Gem Resolution

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

### Running Bundler

Once a manifest file has been created, the only thing that needs to be done
is to run the `gem bundle` command anywhere in your application. The script
will load the manifest file, resolve all the dependencies, download all
needed gems, and install them into the specified directory.

Every time an update is made to the manifest file, run `gem bundle` again to
get the changes installed. This will only check the remote sources if your
currently installed gems do not satisfy the `Gemfile`. If you want to force
checking for updates on the remote sources, use the `--update` option.

### Remote deploys

When you run `gem bundle`, the following steps occur:

1. Gemfile is read in
2. The gems specified in the Gemfile are resolved against the gems
   already in your bundle. If the dependencies resolve, skip to step 5.
3. If the dependencies in your Gemfile cannot be fully resolved
   against the gems already in the bundle, the metadata for each
   source is fetched.
4. The gems in the Gemfile are resolved against the full list of
   available gems in all sources, and the resulting gems are downloaded
5. Each gem that has been downloaded but not yet expanded is expanded
   into the local directory. This expansion process also installs
   native gems.

As you can see, if you run gem bundle twice in a row, it will do nothing the
second time, since the gems obviously resolve against the installed gems,
and they are all expanded.

This also means that if you run `gem bundle`, and .gitignore the expanded
copies, leaving only the cached `.gem` files, you can run `gem bundle` again
on the remote system, and it will only expand out the gems (but not
resolve or download `.gem` files). This also means that native gems
will be compiled for the target platform without requiring that the
`.gem` file itself be downloaded from a remote gem server.

Assuming a Rails app with Bundler's standard setup, add something like
this to your top-level `.gitignore` to only keep the cache:

    bin/*
    vendor/gems/*
    !vendor/gems/cache/

Make sure that you explicitly `git add vendor/gems/cache` before you commit.

### Gems with compile-time options

Some gems require you to pass compile-time options to the gem install command.
For instance, to install mysql, you might do:

    gem install mysql -- --with-mysql-config=/usr/local/lib/mysql

You can pass these options to the bundler by creating a YAML file containing
the options in question:

    mysql:
      mysql-config: /usr/local/lib/mysql

You can then point the bundler at the file:

    gem bundle --build-options build_options.yml

In general, you will want to keep the build options YAML out of version control,
and provide the appropriate options for the system in question.

### Running your application

The easiest way to run your application is to start it with an executable
copied to the specified bin directory (by default, simply bin). For example,
if the application in question is a rack app, start it with `bin/rackup`.
This will automatically set the gem environment correctly.

Another way to run arbitrary ruby code in context of the bundled gems is to
run it with the `gem exec` command. For example:

    gem exec ruby my_ruby_script.rb

You can use `gem exec bash` to enter a shell that will run all binaries in
the current context.

Yet another way is to manually require the environment file first. This is
located in `[bundle_path]/gems/environment.rb`. For example:

    ruby -r vendor/gems/environment.rb my_ruby_script.rb

### Using Bundler with Rails today

It should be possible to use Bundler with Rails today. Here are the steps
to follow.

* In your rails app, create a Gemfile and specify the gems that your
  application depends on. Make sure to specify rails as well:

        gem "rails", "2.1.2"
        gem "will_paginate"

        # Optionally, you can disable system gems all together and only
        # use bundled gems.
        disable_system_gems

* Run `gem bundle`

* You can now use rails if you prepend `gem exec` to every call to `script/*`
  but that isn't fun.

* At the top of `config/preinitializer.rb`, add the following line:

    require "#{RAILS_ROOT}/vendor/gems/environment"

In theory, this should be enough to get going.

## To require rubygems or not

Ideally, no gem would assume the presence of rubygems at runtime. Rubygems provides
enough features so that this isn't necessary. However, there are a number of gems
that require specific rubygems features.

If the `disable_rubygems` option is used, Bundler will stub out the most common
of these features, but it is possible that things will not go as intended quite
yet. So, if you are brave, try your code without rubygems at runtime.

This is different from the `disable_system_gems` option, which uses the rubygems
library, but prevents system gems from being loaded; only gems that are bundled
will be available to your application. This option guarantees that dependencies
of your application will be available to a remote system.

## Known Issues

* When a gem points to a git repository, the git repository will be cloned
  every time Bundler does a gem dependency resolve.

## Reporting bugs

Please report all bugs on the github issue tracker for the project located
at:

    http://github.com/wycats/bundler/issues/
