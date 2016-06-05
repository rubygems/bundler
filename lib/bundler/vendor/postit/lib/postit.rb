require 'postit/environment'
require 'postit/installer'
require 'postit/parser'
require 'postit/version'
require 'rubygems'

module BundlerVendoredPostIt
  def self.setup
    load File.expand_path('../postit/setup.rb', __FILE__)
  end

  def self.bundler_version
    defined?(Bundler::VERSION) && Bundler::VERSION
  end
end
