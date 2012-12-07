# Bundler: a gem to bundle gems [![Build Status](https://secure.travis-ci.org/carlhuda/bundler.png?branch=master)](http://travis-ci.org/carlhuda/bundler)

Bundler manages the gems that a ruby application depends on. Given a list of gems, it can automatically download and install those gems, as well as any other gems needed by the gems that are listed. Before installing gems, it checks the versions of every gem to make sure that they are compatible, and can all be loaded at the same time. After the gems have been installed, Bundler can help you update some or all of them when new versions become available. Finally, it records the exact versions that have been installed, so that others can install the exact same gems.

### Installation and usage

See [gembundler.com](http://gembundler.com) for installation and usage instructions. tl;dr:

```
gem install bundler
bundle init
echo "gem 'rails'" >> Gemfile
bundle install
bundle exec rails new myapp
```

### Troubleshooting

For help with common problems, see [ISSUES](https://github.com/carlhuda/bundler/blob/master/ISSUES.md).

### Development

To see what has changed in recent versions of Bundler, see the [CHANGELOG](https://github.com/carlhuda/bundler/blob/master/CHANGELOG.md).

The `master` branch contains our current progress towards version 1.3. Versions 1.0 to 1.2 each have their own stable branches. Please submit bugfixes as pull requests to the stable branch for the version you would like to fix.

### Other questions

Feel free to chat with the Bundler core team (and many other users) on IRC in the  [#bundler](irc://irc.freenode.net/bundler) channel on Freenode, or via email on the [Bundler mailing list](http://groups.google.com/group/ruby-bundler).
