# Psych could be a gem
begin
  gem 'psych'
rescue Gem::LoadError
end if defined?(Gem)

# Psych from stdlib, but only if Syck isn't loaded
begin
  require 'psych'
rescue LoadError
end unless defined?(Syck)

# Psych might NOT EXIST AT ALL, so fall back on yaml
require 'yaml' unless defined?(YAML)

module Bundler
  # now we need a unified Yaml syntax error
  if defined?(Psych::SyntaxError) # Psych
    YamlSyntaxError = Psych::SyntaxError
  else # Syck just raises an ArgmuentError
    YamlSyntaxError = ArgumentError
  end
end