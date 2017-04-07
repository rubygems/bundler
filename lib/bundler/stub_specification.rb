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

    def full_gem_path
      stub.full_gem_path
    end

    if Bundler.rubygems.provides?(">= 2.2.0")
      def full_require_paths
        stub.full_require_paths
      end
    end

    def loaded_from
      stub.loaded_from
    end

    if Bundler.rubygems.stubs_provide_full_functionality?
      def matches_for_glob(glob)
        stub.matches_for_glob(glob)
      end
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
          Bundler.rubygems.stub_set_spec(stub, rs)
        end

        unless rs
          raise GemspecError, "The gemspec for #{full_name} at #{loaded_from}" \
            " was missing or broken. Try running `gem pristine #{name} -v #{version}`" \
            " to fix the cached spec."
        end

        rs.source = source

        rs
      end
    end
  end
end
