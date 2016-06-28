# frozen_string_literal: true
module Bundler
  class Source
    autoload :Rubygems, "bundler/source/rubygems"
    autoload :Path,     "bundler/source/path"
    autoload :Git,      "bundler/source/git"

    attr_accessor :dependency_names

    def unmet_deps
      specs.unmet_dependency_names
    end

    def version_message(spec)
      message = "#{spec.name} #{spec.version}"

      if Bundler.locked_gems
        locked_spec = Bundler.locked_gems.specs.find {|s| s.name == spec.name }
        locked_spec_version = locked_spec.version if locked_spec
        if locked_spec_version && spec.version != locked_spec_version
          message += " (#{Bundler.ui.add_color("was #{locked_spec_version}", :green)})"
        end
      end

      message
    end

    def can_lock?(spec)
      spec.source == self
    end

    # it's possible that gems from one source depend on gems from some
    # other source, so now we download gemspecs and iterate over those
    # dependencies, looking for gems we don't have info on yet.
    def double_check_for(*)
    end

    def include?(other)
      other == self
    end
  end
end
