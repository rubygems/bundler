require 'erb'
require 'rubygems/dependency_installer'

module Bundler
  # Runs the install procedures for a specific Gemfile: see Installer#run.
  #
  # Firstly, this command will check to see if Bundler.bundle_path exists
  # and if not then will create it. This is usually the location of gems
  # on the system, be it RVM or at a system path.
  #
  # Secondly, it checks if Bundler has been configured to be "frozen"
  # Frozen ensures that the Gemfile and the Gemfile.lock file are matching.
  # This stops a situation where a developer may update the Gemfile but may not run
  # `bundle install`, which leads to the Gemfile.lock file not being correctly updated.
  # If this file is not correctly updated then any other developer running
  # `bundle install` will potentially not install the correct gems.
  #
  # Thirdly, Bundler checks if there are any dependencies specified in the Gemfile using
  # Bundler::Environment#dependencies. If there are no dependencies specified then
  # Bundler returns a warning message stating so and this method returns.
  #
  # Fourthly, Bundler checks if the default lockfile (Gemfile.lock) exists, and if so
  # then proceeds to set up a defintion based on the default gemfile (Gemfile) and the
  # default lock file (Gemfile.lock). However, this is not the case if the platform is different
  # to that which is specified in Gemfile.lock, or if there are any missing specs for the gems.
  #
  # Fifthly, Bundler resolves the dependencies either through a cache of gems or by remote.
  # This then leads into the gems being installed, along with stubs for their executables,
  # but only if the --binstubs option has been passed or Bundler.options[:bin] has been set
  # earlier.
  #
  # Sixthly, a new Gemfile.lock is created from the installed gems to ensure that the next time
  # that a user runs `bundle install` they will receive any updates from this process.
  #
  # Finally: TODO add documentation for how the standalone process works.
  class LockingInstaller < Installer

    def initialize(root, definition)
      super(root, definition)
      @locker = Locker.new(root, definition)
    end

    # Overrides the method in Installer to make sure we generate the
    # lockfile only *after* a successful install.
    def install(options)
      @locker.resolve(options)
      super(options)
      @locker.lock
    end


  end
end
