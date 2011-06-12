if defined?(Thor)
  Bundler.ui.warn "Thor has already been required. " +
    "This may cause Bundler to malfunction in unexpected ways."
end
$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'thor/actions'
