require 'bundler/cli/common'

module Bundler
  class CLI::Show
    attr_reader :options, :gem_name
    def initialize(options, gem_name)
      @options = options
      @gem_name = gem_name
    end

    def run
      Bundler.ui.silence do
        Bundler.definition.validate_ruby!
        Bundler.load.lock
      end

      if gem_name
        if gem_name == "bundler"
          path = File.expand_path("../../../..", __FILE__)
        else
          spec = Bundler::CLI::Common.select_spec(gem_name, :regex_match)
          return unless spec
          path = spec.full_gem_path
          if !File.directory?(path)
            Bundler.ui.warn "The gem #{gem_name} has been deleted. It was installed at:"
          end
        end
        return Bundler.ui.info(path)
      end

      if options[:paths]
        Bundler.load.specs.sort_by { |s| s.name }.map do |s|
          Bundler.ui.info s.full_gem_path
        end
      else
        Bundler.ui.info "Gems included by the bundle:"
        Bundler.load.specs.sort_by { |s| s.name }.each do |s|
          desc = "  * #{s.name} (#{s.version}#{s.scm_version})"
          if @options[:verbose]
            latest = Gem::Specification.latest_specs.find { |l| l.name == s.name }
            Bundler.ui.info <<D
#{desc}
\tSummary:  #{s.summary || 'No description available.'}
\tHomepage: #{s.homepage || 'No website available.'}
\tStatus:   #{outdated?(s, latest) ? "Outdated - #{s.version} < #{latest.version}" : "Up to date"}
D
          else
            Bundler.ui.info desc
          end
        end
      end
    end

    private

    def outdated?(current, latest)
      return false unless latest
      Gem::Version.new(current.version) < Gem::Version.new(latest.version)
    end
  end
end
