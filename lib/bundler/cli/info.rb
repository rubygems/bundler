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
      begin
        gem = Gem::Specification.find_by_name(gem_name)
        spec = gem if gem.default_gem?
      rescue Gem::MissingSpecError
      end

      spec ||= Bundler::CLI::Common.select_spec(gem_name, :regex_match)
      return unless spec
      return print_gem_path(spec) if @options[:path]
      print_gem_info(spec)
    end

  private

    def print_gem_path(spec)
      Bundler.ui.info spec.full_gem_path
    end

    def print_gem_info(spec)
      gem_info = String.new
      gem_info << "  * #{spec.name} (#{spec.version}#{spec.git_version})\n"
      gem_info << "\tSummary: #{spec.summary}\n" if spec.summary
      gem_info << "\tHomepage: #{spec.homepage}\n" if spec.homepage
      gem_info << "\tPath: #{spec.full_gem_path}\n"
      Bundler.ui.info gem_info
    end
  end
end
