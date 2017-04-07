# frozen_string_literal: true
require "bundler/remote_specification"

module Bundler
  class StubSpecification < RemoteSpecification
    def self.from_stub(stub)
      spec = new(stub.name, stub.version, stub.platform, nil)
      spec.stub = stub
      spec
    end

    attr_accessor :stub, :ignored

    def to_yaml
      _remote_specification.to_yaml
    end

    # @!group Stub Delegates

    if Bundler.rubygems.provides?(">= 2.3")
      # This is defined directly to avoid having to load every installed spec
      def missing_extensions?
        stub.missing_extensions?
      end
    end

    def activated
      stub.activated
    end

    def activated=(activated)
      stub.instance_variable_set(:@activated, activated)
    end

    def default_gem
      stub.default_gem
    end

    # This is what we do in bundler/rubygems_ext
    def full_gem_path
      # this cannot check source.is_a?(Bundler::Plugin::API::Source)
      # because that _could_ trip the autoload, and if there are unresolved
      # gems at that time, this method could be called inside another require,
      # thus raising with that constant being undefined. Better to check a method
      if source.respond_to?(:path) || (source.respond_to?(:bundler_plugin_api_source?) && source.bundler_plugin_api_source?)
        Pathname.new(loaded_from).dirname.expand_path(source.root).to_s.untaint
      else
        rg_full_gem_path
      end
    end

    def full_require_paths
      stub.full_require_paths
    end

    def loaded_from
      stub.loaded_from
    end

    def matches_for_glob
      stub.matches_for_glob
    end

    def raw_require_paths
      stub.raw_require_paths
    end

    # This is what we do in bundler/rubygems_ext
    # full_require_paths is always implemented in versions that have stubs
    def load_paths
      full_require_paths
    end

  private

    def _remote_specification
      @_remote_specification ||= begin
        rs = stub.to_spec
        if rs.equal?(self) # happens when to_spec gets the spec from Gem.loaded_specs
          rs = Gem::Specification.load(loaded_from)
          stub.instance_variable_set(:@spec, rs)
        end

        unless rs
          raise GemspecError, "The gemspec for #{full_name} at #{loaded_from}" \
            " was missing or broken. Try running `gem pristine #{name} -v #{version}`" \
            " to fix the cached spec."
        end

        rs
      end
    end
  end
end
