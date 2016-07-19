# frozen_string_literal: true
Artifice.deactivate if defined?(Artifice)
Gem::Request::ConnectionPools.client = ::Net::HTTP if defined?(Gem::Request::ConnectionPools)
class Gem::RemoteFetcher
  @fetcher = nil
end

class Gem::Platform
  @local = nil
end
Gem.platforms.clear

$bundler_spec_stubbed_constants ||= {} # rubocop:disable Style/GlobalVars
$bundler_spec_stubbed_constants.each do |(mod, const), val| # rubocop:disable Style/GlobalVars
  mod.send(:remove_const, const) if mod.send(:const_defined?, const)
  mod.send(:const_set, const, val) if val
end
$bundler_spec_stubbed_constants.clear # rubocop:disable Style/GlobalVars

ENV.delete("BUNDLER_SPEC_ARTIFICE_ENDPOINT")
