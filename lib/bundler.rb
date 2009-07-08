require "rubygems/remote_fetcher"
require "rubygems/installer"
require "bundler/finder"
require "bundler/environment"
require "bundler/gem_specification"

require File.expand_path(File.join(File.dirname(__FILE__), "..", "gem_resolver", "lib", "gem_resolver"))