# frozen_string_literal: true
module Bundler
  class CLI::Check
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      if options[:path]
        Bundler.settings[:path] = File.expand_path(options[:path])
      end

      begin
        definition = Bundler.definition
        definition.validate_ruby!
        not_installed = definition.missing_specs
      rescue GemNotFound, VersionConflict
        Bundler.ui.error "Bundler can't satisfy your #{SharedHelpers.gemfile_name}'s dependencies."
        Bundler.ui.warn "Install missing gems with `bundle install`."
        exit 1
      end

      if not_installed.any?
        Bundler.ui.error "The following gems are missing"
        not_installed.each {|s| Bundler.ui.error " * #{s.name} (#{s.version})" }
        Bundler.ui.warn "Install missing gems with `bundle install`"
        exit 1
      elsif !Bundler.default_lockfile.exist? && Bundler.settings[:frozen]
        Bundler.ui.error "This bundle has been frozen, but there is no #{SharedHelpers.lockfile_name} present"
        exit 1
      else
        Bundler.load.lock(:preserve_unknown_sections => true) unless options[:"dry-run"]
        Bundler.ui.info "#{SharedHelpers.gemfile_name}'s dependencies are satisfied"
      end
    end
  end
end
