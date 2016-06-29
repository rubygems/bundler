# frozen_string_literal: true

module BundlerVendoredPostIt; end
require "bundler/vendor/postit/lib/postit"
require "rubygems"

environment = BundlerVendoredPostIt::PostIt::Environment.new([])
version = Gem::Requirement.new(environment.bundler_version)

installed_version =
  if defined?(Bundler::VERSION)
    Bundler::VERSION
  else
    File.read(File.expand_path("../version.rb", __FILE__)) =~ /VERSION = "(.+)"/
    $1
  end
installed_version &&= Gem::Version.new(installed_version)

if !version.satisfied_by?(installed_version)
  begin
    installer = BundlerVendoredPostIt::PostIt::Installer.new(version)
    installer.install!
  rescue => e
    abort <<-EOS.strip
Installing the inferred bundler version (#{version}) failed.
If you'd like to update to the current bundler version (#{installed_version}) in this project, run `bundle update --bundler`.
The error was: #{e}
    EOS
  end

  if deleted_spec = Gem.loaded_specs.delete("bundler")
    deleted_spec.full_require_paths.each {|path| $:.delete(path) }
  else
    $:.delete(File.expand_path("../..", __FILE__))
  end
  gem "bundler", version
else
  begin
    gem "bundler", version
  rescue LoadError
    $:.unshift(File.expand_path("../..", __FILE__))
  end
end

running_version = begin
  require "bundler/version"
  Bundler::VERSION
rescue LoadError, NameError
  nil
end

if Gem::Requirement.new(">= 1.13.pre".dup).satisfied_by?(Gem::Version.new(running_version))
  ENV["BUNDLE_POSTIT_TRAMPOLINING_VERSION"] = installed_version.to_s
elsif ARGV.empty? || ARGV.any? {|a| %w(install i).include? a }
  puts <<-WARN.strip
You're running Bundler #{installed_version} but this project uses #{running_version}. To update, run `bundle update --bundler`.
  WARN
end

if !Gem::Version.correct?(running_version.to_s) || !version.satisfied_by?(Gem::Version.create(running_version))
  abort "The running bundler (#{running_version}) does not match the required `#{version}`"
end
