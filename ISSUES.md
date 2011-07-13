# Bundler Issues

## Frequently encountered issues

### REE and Zlib::GzipFile::Error

Ruby Enterprise Edition users may see a `Zlib::GzipFile::Error` while installing gems. It is due to [a bug in REE](http://code.google.com/p/rubyenterpriseedition/issues/detail?id=45). You may be able to resolve the issue by upgrading REE, or changing to a different interpreter.

### Rake activation error

Anyone who has installed the Spork gem may see activation errors while running `rake` directly. This is because old versions of Spork would [install the newest rake using a mkmf file](https://github.com/timcharper/spork/issues/119). To resolve the issue, update the Spork version requirement in your Gemfile to at least `"~>0.8.5"` or `"~>0.9.0.rc8"`.

## Troubleshooting

Instructions for common Bundler use-cases can be found on the [Bundler documentation site](http://gembundler.com/v1.0/).

Detailed information about each Bundler command, including help with common problems, can be found in the [Bundler man pages](http://gembundler.com/man/bundle.1.html).

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

Instructions that allow the Bundler team to reproduce your issue are vitally important. When you report a bug, please include the following information:

  - The command you ran
  - Exception backtrace(s), if any
  - Your Gemfile
  - Your Gemfile.lock
  - Your Bundler configuration settings (run `bundle config`)
  - What version of bundler you are using (run `bundle -v`)
  - What version of Ruby you are using (run `ruby -v`)
  - What version of Rubygems you are using (run `gem -v`)
  - Whether you are using RVM, and if so what version (run `rvm -v`)
  - Whether you have the `rubygems-bundler` gem, which can break gem binares
  - Whether you have the `open_gem` gem, which can cause rake activation conflicts


If you are using Rails 2.3, please also include:

  - Your boot.rb file
  - Your preinitializer.rb file
  - Your environment.rb file

[Create a gist](https://gist.github.com) containing all of that information, then visit the [Bundler issue tracker](https://github.com/carlhuda/bundler) and create a new ticket describing your problem and linking to your gist.
