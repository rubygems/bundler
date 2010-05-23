require 'erb'

module Bundler
  class Environment
    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    # TODO: Remove this method. It's used in cli.rb still
    def index
      @definition.index
    end

    def requested_specs
      @requested_specs ||= begin
        groups = @definition.groups - Bundler.settings.without
        groups.map! { |g| g.to_sym }
        specs_for(groups)
      end
    end

    def specs
      @definition.specs
    end

    def dependencies
      @definition.dependencies
    end

    def lock
      write_yml_lock
    end

    def update(*gems)
      # Nothing
    end

  private

    def specs_for(groups)
      deps = dependencies.select { |d| (d.groups & groups).any? }
      specs.for(deps)
    end

    # ==== Locking

    def write_yml_lock
      contents = lock_content
      File.open(root.join('Gemfile.lock'), 'w') do |f|
        f.puts contents
      end
    end

    def lock_content
      out = ""

      @definition.sources.each do |source|
        # Add the source header
        out << source.to_lock
        # Find all specs for this source
        specs.
          select  { |s| s.source == source }.
          sort_by { |s| s.name }.
          each do |spec|
            out << spec.to_lock
        end
        out << "\n"
      end

      out << "DEPENDENCIES\n"

      @definition.dependencies.
        sort_by { |d| d.name }.
        each do |dep|
          out << dep.to_lock
      end

      out
    end
  end
end
