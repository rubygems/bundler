require "uri"
require 'rubygems/user_interaction'
require "rubygems/installer"
require "rubygems/spec_fetcher"
require "rubygems/format"
require "digest/sha1"
require "fileutils"

module Bundler
  module Source
    autoload :Rubygems, "bundler/source/rubygems"
    autoload :Path,     "bundler/source/path"
    autoload :Git,      "bundler/source/git"
  end
end
