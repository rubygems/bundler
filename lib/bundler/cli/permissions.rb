# frozen_string_literal: true

module Bundler
  class CLI::Permissions
    attr_reader :bundle_path

    def initialize
      @bundle_path = Bundler.bundle_path
    end

    def run
      return permission_error   if not_permissible?
      return permission_warning if permissible_and_not_owner?

      Bundler.ui.info "The Gemfile's permissions are satisfied"
    end

    private

    def permission_warning
      Bundler.ui.warn "WARN"
    end

    def permission_error
      Bundler.ui.error "ERROR"
    end

    def not_permissible?
      !permissible?
    end

    def permissible?
      (bundle_path.writable? && bundle_path.readable?)
    end

    def permissible_and_not_owner?
      permissible? && not_owner?
    end

    def owner?
      bundle_path.owned?
    end

    def not_owner?
      !owner?
    end
  end
end
