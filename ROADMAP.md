# 1.0

  - No breaking changes to the Gemfile are expected
  - We expect to modify the format of Gemfile.lock.
    - This should be the final change
    - This means you will not be able to upgrade a locked app
      directly from 0.9 to 1.0.
  - Bundler will automatically generate Gemfile.lock when any
    resolve is successful.
    - This means the bundle lock command will no longer be needed.
  - Bundler will conservatively update Gemfile.lock from the
    last successful resolve if the Gemfile has been modified since
    the last use of bundler.
    - This means that adding a new gem to the Gemfile that does not
      conflict with existing gems will not force an update of other
      gems.
    - This also means that we will not force an update to previously
      resolved dependencies as long as they are compatible with some
      valid version of the new dependency.
    - When removing a gem, bundle install will simply remove it, without
      recalculating all dependencies.
  - We will be adding `bundle update` for the case where you -do-
    wish to re-resolve all dependencies and update everything to the
    latest version.
    - bundle update will also take a gem name, if you want to force
      an update to just a single gem (and its dependencies).
  - There will be a way to install dependencies that require build options
  - We will add groups that are opt-in at install-time, rather than opt-out.
  - We will reduce open bug count to 0 for the final 1.0 release.
  - Some additional features that require more thought. For details,
    see http://github.com/carlhuda/bundler/issues/labels/1.0

# 1.1

  - Stop upgrading 0.9 lockfiles
  - Delete vestigial gems installed into ~/.bundle/ by 0.9