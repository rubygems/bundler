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
      @definition.requested_specs
    end

    def specs
      @definition.specs
    end

    def dependencies
      @definition.dependencies
    end

    def current_dependencies
      @definition.current_dependencies
    end

    def lock
      write_yml_lock
    end

    def update(*gems)
      # Nothing
    end

  private

    # ==== Locking

    def write_yml_lock
      File.open(root.join('Gemfile.lock'), 'w') do |f|
        f.puts @definition.to_lock
      end
    end
  end
end
