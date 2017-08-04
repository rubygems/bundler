[![Version     ](https://img.shields.io/gem/v/bundler.svg?style=flat)](https://rubygems.org/gems/bundler)
[![Build Status](https://img.shields.io/travis/bundler/bundler/master.svg?style=flat)](https://travis-ci.org/bundler/bundler)
[![Code Climate](https://img.shields.io/codeclimate/github/bundler/bundler.svg?style=flat)](https://codeclimate.com/github/bundler/bundler)
[![Inline docs ](http://inch-ci.org/github/bundler/bundler.svg?style=flat)](http://inch-ci.org/github/bundler/bundler)
[![Slack       ](http://bundler-slackin.herokuapp.com/badge.svg)](http://bundler-slackin.herokuapp.com)

# Bundler: a gem to bundle gems

Bundler makes sure Ruby applications run the same code on every machine.

It does this by managing the gems that the application depends on. Given a list of gems, it can automatically download and install those gems, as well as any other gems needed by the gems that are listed. Before installing gems, it checks the versions of every gem to make sure that they are compatible, and can all be loaded at the same time. After the gems have been installed, Bundler can help you update some or all of them when new versions become available. Finally, it records the exact versions that have been installed, so that others can install the exact same gems.

To see what has changed in recent versions of Bundler, see the [CHANGELOG](CHANGELOG.md), or [visit the Bundler site](http://bundler.io) to access the complete documentation.

### Installation and usage

To install:

```
gem install bundler
```

To install a pre-release version (if one is available), run:
```
gem install bundler --pre.
```

Bundler is most commonly used to manage your application's dependencies. For example, these commands will allow you to use Bundler to manage the `rspec` gem for your application:

```
bundle init
echo 'gem "rspec"' >> Gemfile
bundle install
bundle exec rspec
```

### Contributing

While some Bundler contributors are compensated by Ruby Together, the project maintainers make decisions independent of Ruby Together. As a project, we welcome contributions regardless of your affiliation with Ruby Together. So if you'd like to contribute to Bundler, that's awesome, and we <3 you!

We have a [guide with recommended first steps](doc/contributing/README.md) that we suggest anyone interested in contributing to Bundler review first. Once you’ve completed those steps, feel free to start contributing in any of the following ways:

- Adding new sections or making edits to the [documentation website](https://github.com/bundler/bundler-site) and [man pages](https://github.com/bundler/bundler/tree/master/man)
- Fixing typos
- [Triage existing issues](doc/contributing/BUG_TRIAGE.md)
- [Opening new issues](doc/contributing/ISSUES.md) (suggest feature requests, report new bugs)
- [Reviewing pull requests](https://github.com/bundler/bundler/pulls)
- [Backfilling unit tests](https://github.com/bundler/bundler/tree/master/spec/bundler) for modules that [lack coverage](https://codeclimate.com/github/bundler/bundler/coverage)

### Get support

- **Troubleshooting**. If you have either `rubygems-bundler` or `open_gem` installed, please try removing them before filing an issue. For help with common problems, check out the [troubleshooting guide](doc/TROUBLESHOOTING.md).
- **Reporting a bug**. If you’ve tried the troubleshooting guide and something is still not working, you can file an issue. Run `bundle-report-bug` to get all of the information you need to report a bug.
- **Security issues**. For security-related issues, do not open a public ticket. Please send an email to [team@bundler.io](mailto:team@bundler.io) and we will respond within 48 hours.

### Fund this project

<a href="https://rubytogether.org/"><img src="https://rubytogether.org/images/rubies.svg" width="150"></a><br>
<a href="https://rubytogether.org/">Ruby Together</a> pays some Bundler maintainers for their ongoing work. As a grassroots initiative committed to supporting the critical Ruby infrastructure you rely on, Ruby Together is funded entirely by the Ruby community.

Contribute today <a href="https://rubytogether.org/developers">as an individual</a> or (better yet) <a href="https://rubytogether.org/companies">as a company</a> to ensure that Bundler, RubyGems, and other shared tooling is around for years to come!

### Code of Conduct

Everyone interacting in the Bundler project’s codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [Bundler code of conduct](https://github.com/bundler/bundler/blob/master/CODE_OF_CONDUCT.md).
