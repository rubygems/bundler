## Bundler : A gem to bundle gems

Bundler is a tool that manages gem dependencies for your ruby application. It
takes a gem manifest file and is able to fetch, download, and install the gems
and all child dependencies specified in this manifest. It can manage any update
to the gem manifest file and update the bundle's gems accordingly. It also lets
you run any ruby code in context of the bundle's gem environment.

## Installation and usage

See [gembundler.com](http://gembundler.com) for up-to-date installation and usage instructions

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

For information about future plans and changes that will happen in the future, see the [ROADMAP](http://github.com/carlhuda/bundler/blob/master/ROADMAP.md). To see what has changed in each version of bundler, starting with 0.9.5, see the [CHANGELOG](http://github.com/carlhuda/bundler/blob/master/CHANGELOG.md).

### Other questions

Any remaining questions may be asked via IRC in [#bundler](irc://irc.freenode.net/bundler) on Freenode, or via email on the [Bundler mailing list](http://groups.google.com/group/ruby-bundler).

### Issues

See [ISSUES](http://github.com/carlhuda/bundler/blob/master/ISSUES.md).