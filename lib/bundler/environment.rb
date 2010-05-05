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

    def locked?
      File.exist?("#{root}/Gemfile.lock")
    end

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
        f.puts details
      end
    end

    def details
      output = ""

      pinned_sources = dependencies.map {|d| d.source }
      all_sources    = @definition.sources.map {|s| s }

      specified_sources = all_sources - pinned_sources

      unless specified_sources.length == 1 && specified_sources.first.remotes.empty?
        output << "sources:\n"

        specified_sources.each do |source|
          o = source.to_lock
          output << "  #{source.to_lock}\n" unless o.empty?
        end
        output << "\n"
      end

      unless @definition.dependencies.empty?
        output << "dependencies:\n"
        @definition.dependencies.sort_by {|d| d.name }.each do |dependency|
          output << dependency.to_lock
        end
        output << "\n"
      end

      output << "specs:\n"
      specs.sort_by {|s| s.name }.each do |spec|
        output << spec.to_lock
      end

      output
    end
  end
end
