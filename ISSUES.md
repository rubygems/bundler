# Bundler Issues

## Troubleshooting

Instructions for common Bundler use-cases can be found on the [Bundler documentation site](http://gembundler.com/v1.0/). Detailed information about each Bundler command, including help with common problems, can be found in the [Bundler man pages](http://gembundler.com/man/bundle.1.html).

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

If you are still having problems, please report issues to the [Bundler issue tracker](http://github.com/carlhuda/bundler/issues/).

Instructions that allow the Bundler team to reproduce your issue are vitally important. When you report a bug, please create a gist of the following information and include a link in your ticket:

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
