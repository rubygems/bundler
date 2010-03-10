## 0.9.12 (???)

Bugfixes:

  - perform a topological sort on resolved gems (#191)

## 0.9.11 (March 9, 2010)

  - added roadmap with future development plans

Features:

  - install command can take the path to the gemfile with --gemfile (#125)
  - unknown command line options are now rejected (#163)
  - exec command hugely sped up while locked (#177)
  - show command prints the install path if you pass it a gem name (#148)
  - open command edits an installed gem with $EDITOR (#148)
  - Gemfile allows assigning an array of groups to a gem (#114)
  - Gemfile allows :tag option on :git sources
  - improve backtraces when a gemspec is invalid
  - improve performance by installing gems from the cache if present

Bugfixes:

  - normalize parameters to Bundler.require (#153)
  - check now checks installed gems rather than cached gems (#162)
  - don't update the gem index when installing after locking (#169)
  - bundle parenthesises arguments for 1.8.6 (#179)
  - gems can now be assigned to multiple groups without problems (#135)
  - fix the warning when building extensions for a gem from git with Rubygems 1.3.6
  - fix a Dependency.to_yaml error due to accidentally including sources and groups
  - don't reinstall packed gems
  - fix gems with git sources that are private repositories

## 0.9.10 (March 1, 2010)

  - depends on Rubygems 1.3.6

Bugfixes:

  - support locking after install --without
  - don't reinstall gems from the cache if they're already in the bundle
  - fixes for Ruby 1.8.7 and 1.9

## 0.9.9 (February 25, 2010)

Bugfixes:

  - don't die if GEM_HOME is an empty string
  - fixes for Ruby 1.8.6 and 1.9

## 0.9.8 (February 23, 2010)

Features:

  - pack command which both caches and locks
  - descriptive error if a cached gem is missing
  - remember the --without option after installing
  - expand paths given in the Gemfile via the :path option
  - add block syntax to the git and group options in the Gemfile
  - support gems with extensions that don't admit they depend on rake
  - generate gems using gem build gemspec so git gems can have native extensions
  - print a useful warning if building a gem fails
  - allow manual configuration via BUNDLE_PATH

Bugfixes:

  - eval gemspecs in the gem directory so relative paths work
  - make default spec for git sources valid
  - don't reinstall gems that are already packed

## 0.9.7 (February 17, 2010)

Bugfixes:

  - don't say that a gem from an excluded group is "installing"
  - improve crippling rubygems in locked scenarios

## 0.9.6 (February 16, 2010)

Features:

  - allow String group names
  - a number of improvements in the documentation and error messages

Bugfixes:

  - set SourceIndex#spec_dirs to solve a problem involving Rails 2.3 in unlocked mode
  - ensure Rubygems is fully loaded in Ruby 1.9 before patching it
  - fix `bundle install` for a locked app without a .bundle directory
  - require gems in the order that the resolver determines
  - make the tests platform agnostic so we can confirm that they're green on JRuby
  - fixes for Ruby 1.9

## 0.9.5 (Feburary 12, 2010)

Features:

  - added support for :path => "relative/path"
  - added support for older versions of git
  - added `bundle install --disable-shared-gems`
  - Bundler.require fails silently if a library does not have a file on the load path with its name
  - Basic support for multiple rubies by namespacing the default bundle path using the version and engine

Bugfixes:

  - if the bundle is locked and .bundle/environment.rb is not present when Bundler.setup is called, generate it
  - same if it's not present with `bundle check`
  - same if it's not present with `bundle install`
