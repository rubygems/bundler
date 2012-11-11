# Bundler Issues

So! You're having problems with Bundler. This file is here to help. If you're running into an error, try reading the rest of this file for help. If you can't figure out how to solve your problem, there are also instructions on how to report a bug.

## Documentation

Instructions for common Bundler uses can be found on the [Bundler documentation site](http://gembundler.com/).

Detailed information about each Bundler command, including help with common problems, can be found in the [Bundler man pages](http://gembundler.com/man/bundle.1.html).

## Troubleshooting

### Heroku errors

Please open a ticket with Heroku if you're having trouble deploying. They have a professional support team who can help you resolve Heroku issues far better than the Bundler team can. If the problem that you are having turns out to be a bug in Bundler itself, Heroku support can get the exact details to us.

### Something else

After reading the documentation, try these troubleshooting steps:

    # remove user-specific gems and git repos
    rm -rf ~/.bundle/ ~/.gem/

    # remove system-wide git repos and git checkouts
    rm -rf $GEM_HOME/bundler/ $GEM_HOME/cache/bundler/

    # remove project-specific settings and git repos
    rm -rf .bundle/

    # remove project-specific cached .gem files
    rm -rf vendor/cache/

    # remove the saved resolve of the Gemfile
    rm -rf Gemfile.lock

    # try to install one more time
    bundle install

## Reporting unresolved problems

The Bundler team needs to know some things in order to diagnose and hopefully fix the bug you've found. When you report a bug, please include the following information:

  - The command you ran
  - Exception backtrace(s), if any
  - Your Gemfile
  - Your Gemfile.lock
  - Your Bundler configuration settings (run `bundle config`)
  - What version of bundler you are using (run `bundle -v`)
  - What version of Ruby you are using (run `ruby -v`)
  - What version of Rubygems you are using (run `gem -v`)
  - Whether you are using RVM, and if so what version (run `rvm -v`)
  - Whether you have the `rubygems-bundler` gem, which can break gem binares (run `gem list rubygems-bundler`)
  - Whether you have the `open_gem` gem, which can cause rake activation conflicts (run `gem list open_gem`)

If you are using Rails 2.3, please also include:

  - Your boot.rb file
  - Your preinitializer.rb file
  - Your environment.rb file

[Create a gist](https://gist.github.com) containing all of that information, then visit the [Bundler issue tracker](https://github.com/carlhuda/bundler/issues) and [create a ticket](https://github.com/carlhuda/bundler/issues/new) describing your problem and linking to your gist.

Thanks for reporting issues and making Bundler better!