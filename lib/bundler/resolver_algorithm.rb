module Bundler
  module ResolverAlgorithm
    autoload :Base, "bundler/resolver_algorithm/base"
    autoload :RecursiveResolver, "bundler/resolver_algorithm/recursive_resolver"
    autoload :SatResolver, "bundler/resolver_algorithm/sat_resolver"
  end
end
