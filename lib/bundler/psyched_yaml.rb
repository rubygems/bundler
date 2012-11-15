begin
  # Psych could be a gem, so set up the load path
  gem 'psych' if defined?(gem)

  # Psych could just be in the stdlib
  # but it's too late if Syck is already loaded
  require 'psych' unless defined?(Syck)
rescue LoadError
  # apparently Psych wasn't available. Oh well.
ensure
  # at least load the YAML stdlib, whatever that may be
  require 'yaml'
end

module Bundler
  # On encountering invalid YAML,
  # Psych raises Psych::SyntaxError
  # Syck raises ArgumentError
  if defined?(::Psych::SyntaxError)
    YamlSyntaxError = ::Psych::SyntaxError
  else
    YamlSyntaxError = ::ArgumentError
  end
end
