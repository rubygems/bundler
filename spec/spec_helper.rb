$:.push File.join(File.dirname(__FILE__), '..', 'lib')
$:.push File.join(File.dirname(__FILE__), '..', 'gem_resolver', 'lib')
require "gem_resolver/builders"
require "bundler"

Spec::Runner.configure do |config|
  config.include GemResolver::Builders
end