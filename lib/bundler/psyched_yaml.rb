# Psych could be a gem
begin
  gem 'psych'
rescue Gem::LoadError
end if defined?(Gem)

# Psych from stdlib if Syck isn't loaded
begin
  require 'psych'
rescue LoadError
end unless defined?(Syck)

# Psych might NOT EXIST AT ALL, so use the Yaml
require 'yaml'

module Bundler
  # Now we need a single unified Yaml syntax error
  if defined?(Psych::SyntaxError)
    YamlSyntaxError = Psych::SyntaxError
  else
    YamlSyntaxError = ArgumentError
  end
end