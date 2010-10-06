# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler/version'

Gem::Specification.new do |s|
  s.name        = "bundler"
  s.version     = Bundler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Carl Lerche", "Yehuda Katz", "André Arko"]
  s.email       = ["carlhuda@engineyard.com"]
  s.homepage    = "http://gembundler.com"
  s.summary     = %q{The best way to manage your application's dependencies}
  s.description = %q{Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "bundler"

  s.add_development_dependency "ronn"
  s.add_development_dependency "rspec"

  # Man files are required because they are ignored by git
  man_files            = Dir.glob("lib/bundler/man/**/*")
  s.files              = `git ls-files`.split("\n") + man_files
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = %w(bundle)
  s.default_executable = "bundle"
  s.require_paths      = ["lib"]
end
