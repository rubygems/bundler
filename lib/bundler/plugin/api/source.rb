# frozen_string_literal: true

module Bundler
  module Plugin::Api::Source
    attr_reader :uri, :options

    def initialize(opts)
      @options = opts
      @uri = opts["uri"]
    end

    def specs
      index = Bundler::Index.new

      files = fetch_gemfiles
      files.each do |file|
        next unless spec = Bundler.load_gemspec(file)
        spec.source = self
        Bundler.rubygems.set_installed_by_version(spec)
        # Validation causes extension_dir to be calculated, which depends
        # on #source, so we validate here instead of load_gemspec
        Bundler.rubygems.validate(spec)

        index << spec
      end

      index
    end

    def install
    end

    def fetch_gemfiles
      raise "Source plugins need to define fetch_gemfile method"
    end
  end
end
