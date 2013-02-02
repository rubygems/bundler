# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'bundler/version'

Gem::Specification.new do |spec|
  spec.name        = 'bundler'
  spec.version     = Bundler::VERSION
  spec.licenses    = ['MIT']
  spec.authors     = ["André Arko", "Terence Lee", "Carl Lerche", "Yehuda Katz"]
  spec.email       = ["andre@arko.net"]
  spec.homepage    = "http://gembundler.com"
  spec.summary     = %q{The best way to manage your application's dependencies}
  spec.description = %q{Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably}

  spec.required_ruby_version     = '>= 1.8.7'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.add_development_dependency 'ronn'
  spec.add_development_dependency 'rspec', '>= 2.11'

  # Man files are required because they are ignored by git
  spec.files         = %w(CHANGELOG.md CONTRIBUTE.md CONTRIBUTING.md ISSUES.md LICENSE.md README.md Rakefile UPGRADING.md bundler.gemspec)
  spec.files        += Dir.glob("lib/**/*.rb")
  spec.files        += Dir.glob("bin/**/*")
  spec.files        += Dir.glob("man/**/*")
  spec.files        += Dir.glob("spec/**/*")
  spec.test_files    = Dir.glob("spec/**/*")

  spec.executables   = %w(bundle)
  spec.require_paths = ["lib"]
end
