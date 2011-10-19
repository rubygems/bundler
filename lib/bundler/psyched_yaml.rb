# Psych could be a gem
begin
  gem 'psych'
rescue Gem::LoadError
end if defined?(Gem)

# Psych could be a stdlib
begin
  # it's too late if Syck is already loaded
  require 'psych' unless defined?(Syck)
rescue LoadError
end

# Psych might NOT EXIST AT ALL
require 'yaml'
