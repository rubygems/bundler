# frozen_string_literal: true

module Bundler
  class CLI::List
    def run
      specs = Bundler.load.specs.reject {|s| s.name == "bundler" }

      return Bundler.ui.info "No gems in the Gemfile" if specs.empty?
      Bundler.ui.info "Gems included by the bundle:"
      specs.sort_by(&:name).each do |s|
        Bundler.ui.info "  * #{s.name} (#{s.version}#{s.git_version})"
      end

      Bundler.ui.info "Use `bundle info` to print more detailed information about a gem"
    end
  end
end
