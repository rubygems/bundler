# frozen_string_literal: true
require "bundler/cli/common"
require "net/http"
require "yaml"

module Bundler
  class CLI::Add
    attr_reader :options, :name, :version
    def initialize(options, name, version)
      @options = options
      @name = name
      @version = version || last_version_number
    end

    def run
      Bundler.default_gemfile.open("a") do |f|
        f.puts
        f.puts output_line
      end
      Bundler.ui.confirm "Added to Gemfile: #{output_line}"
    end

  private

    def last_version_number
      definition = Bundler.definition(true)
      definition.resolve_remotely!
      specs = definition.index[name].sort_by(&:version)
      spec = specs.delete_if {|b| b.respond_to?(:version) && b.version.prerelease? }
      spec = specs.last
      spec.version.to_s
    end

    def output_line
      %(|gem "#{name}", "#{approximate_recommendation}"|)
    end

    def approximate_recommendation
      Gem::Version.new(version).approximate_recommendation
    end
  end
end
