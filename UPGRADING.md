## Bundler 1 to Bundler 2

In the transition from Bundler 1 to Bundler 2, we've made some changes that break backwards compatibility. Each of those changes was carefully selected to make working with Bundler easier to understand, easier to use, and faster. This list will help you get up to speed on the changes, and you'll be back to using Bundler in no time.

### Start with Bundler 1.99

If you're running Bundler 1.x right now, we've created a release specifically to help you migrate to Bundler 2.0. Install Bundler 1.99 and use it. We'll print warnings for anything that's going to change or be removed, so you can get ready for it in advance. Once you're using Bundler 1.99 without any warnings, you should be able to switch to 2.0 and have things just keep working.

#### Changed: Remembered config flags

The way that running `bundle install` with options causes those options to be remembered for all future runs of Bundler has caused a lot of confusion. It's "easy", but it's not the way that any other programs work, and it causes lots of problems when people forget that they once ran Bundler with an option weeks or months before.

In Bundler 2, options passed as flags will not be remembered. This means that if you want to set the `path` option or the `without` option to be remembered, you'll need to do it by running `bundle config path my_path` or `bundle config without production`.

This change is not expected to impact production deployment scripts, because those scripts pass all the options they want to set every time they run `bundle install`.

#### Removed: Deployment helpers

The `bundler/capistrano` and `bundler/vlad` deployment helper files have been removed. Capistrano 3 has built-in Bundler integration in the form of the `capistrano-bundler` gem, and everyone using Capistrano 3 should be using that instead. If for some reason, you are still using Capistrano 2, feel free to copy the Capistrano tasks out of the Bundler 1 file `bundler/deployment.rb` and put them into your app.

#### Removed: `bundle install --binstubs`

The `--binstubs` option has been removed from `bundle install` and replaced with the `bundle binstubs` command. This means that binstubs must be created and checked into version control individually.

The `bundle binstubs [GEM]` command accepts two optional arguments: `--force`, which overwrites existing binstubs if they exist, and `--path=PATH`, which specifies the directory in which the binstubs will be installed (./bin by default).