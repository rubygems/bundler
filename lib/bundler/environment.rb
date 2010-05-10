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
      FileUtils.mkdir_p("#{root}/.bundle")
      write_yml_lock
      write_rb_lock
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

    def write_rb_lock
      begin
        env_file = Bundler.default_gemfile.dirname.join(".bundle/environment.rb")
        env_file.dirname.mkpath
        File.open(env_file, 'w') do |f|
          f.puts <<-RB
require "rubygems"
require "bundler/setup"
          RB
        end
      rescue Errno::EACCES
        Bundler.ui.warn "Cannot write .bundle/environment.rb file"
      end
    end

    def write_yml_lock
      File.open("#{root}/Gemfile.lock", 'w') do |f|
        f.puts lock_content
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
