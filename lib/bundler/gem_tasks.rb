require "rake/clean"
CLOBBER.include "pkg"

require "bundler/gem_helper"
Bundler::GemHelper.install_tasks
