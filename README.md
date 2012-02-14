# Bundler: a gem to bundle gems

Bundler is a tool that manages gem dependencies for your ruby application. It
takes a gem manifest file and is able to fetch, download, and install the gems
and all child dependencies specified in this manifest. It can manage any update
to the gem manifest file and update the bundle's gems accordingly. It also lets
you run any ruby code in context of the bundle's gem environment.

### Installation and usage

See [gembundler.com](http://gembundler.com) for up-to-date installation and usage instructions.

### Troubleshooting

For help with common problems, see [ISSUES](https://github.com/carlhuda/bundler/blob/master/ISSUES.md).

### Development

To see what has changed in recent versions of bundler, see the [CHANGELOG](https://github.com/carlhuda/bundler/blob/master/CHANGELOG.md).

The `master` branch contains our current progress towards version 1.1. Because of that, please submit bugfix pull requests against the `1-0-stable` branch.

### Upgrading from Bundler 0.8 to 0.9 and above

See [UPGRADING](https://github.com/carlhuda/bundler/blob/master/UPGRADING.md).

### Other questions

Feel free to chat with the Bundler core team (and many other users) on IRC in the  [#bundler](irc://irc.freenode.net/bundler) channel on Freenode, or via email on the [Bundler mailing list](http://groups.google.com/group/ruby-bundler).

### Maven Integration (JRuby only)
This version of bundler allows maven dependencies to be included alongside your other Ruby dependencies opening up a whole new world of possibilities! There are two ways to add your maven dependencies:
1) mvn "repo URL (or 'default' for the default repo URL)" do
	gem "mvn:<group_id>:<artifact_id>", "version number"
   end
2) gem "mvn:<group_id>:<artifact_id>", "version number", :mvn=>"repo URL (or 'default' for the default repo URL)"

This integration will download the right jar using maven into your *maven* repo location and simply write the necessary ruby files to require the jars from the
right location in the maven repository. This allows for maven repos and gem repos to live side by side without duplication of binaries and ensure that dependencies
are resolved properly as maven does that automatically. 