require 'postit/environment'
require 'postit/installer'

environment = BundlerVendoredPostIt::Environment.new(ARGV)
version = environment.bundler_version

installer = BundlerVendoredPostIt::Installer.new(version)
installer.install!

gem 'bundler', version

require 'bundler/version'
