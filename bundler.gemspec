# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'bundler/version'

Gem::Specification.new do |s|
  s.name        = 'bundler'
  s.version     = Bundler::VERSION
  s.licenses    = ['MIT']
  s.authors     = ["André Arko", "Terence Lee", "Carl Lerche", "Yehuda Katz"]
  s.email       = ["andre@arko.net"]
  s.homepage    = "http://bundler.io"
  s.summary     = %q{The best way to manage your application's dependencies}
  s.description = %q{Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably}

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_development_dependency 'mustache', '0.99.6'
  s.add_development_dependency 'rdiscount', '~> 1.6'
  s.add_development_dependency 'ronn', '~> 0.7.3'
  s.add_development_dependency 'rspec', '~> 3.0'

  s.files       = `git ls-files -z`.split("\x0")
  s.files      += Dir.glob('lib/bundler/man/**/*') # man/ is ignored by git
  s.test_files  = s.files.grep(%r{^spec/})

  s.executables   = %w(bundle bundler)
  s.require_paths = ["lib"]
end
