# frozen_string_literal: true
require "bundler/cli/common"

module Bundler
  class CLI::Info
    attr_reader :gem_name, :options
    def initialize(options, gem_name)
      @options = options
      @gem_name = gem_name
    end

    def run
      Bundler.ui.silence do
        Bundler.definition.validate_runtime!
        Bundler.load.lock
      end

      spec = Bundler::CLI::Common.select_spec(gem_name, :regex_match)
      return unless spec

      path = spec.full_gem_path
      return Bundler.ui.info(path) if options[:path]

      unless File.directory?(path)
        Bundler.ui.warn("The gem #{gem_name} has been deleted. It was installed at:")
      end

      print_gem_info spec
    end

  private

    def print_gem_info(spec)
      desc = "  * #{spec.name} (#{spec.version}#{spec.git_version})"
      latest = fetch_latest_specs.find {|l| l.name == spec.name }
      Bundler.ui.info <<-END.gsub(/^ +/, "")
        #{desc}
        \tSummary:  #{spec.summary || "No description available."}
        \tHomepage: #{spec.homepage || "No website available."}
        \tStatus:   #{outdated?(spec, latest) ? "Outdated - #{spec.version} < #{latest.version}" : "Up to date"}
      END
    end

    def fetch_latest_specs
      definition = Bundler.definition(true)
      definition.resolve_remotely!
      definition.specs
    end

    def outdated?(current, latest)
      return false unless latest
      Gem::Version.new(current.version) < Gem::Version.new(latest.version)
    end
  end
end
