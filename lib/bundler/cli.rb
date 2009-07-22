module Bundler
  module CLI

    module_function

    def default_manifest
      return unless root?
      root.join("Gemfile")
    end

    def default_path
      return unless root?
      root.join("vendor", "gems")
    end

    def default_bindir
      return unless root?
      root.join("bin")
    end

    def root
      return @root if @root

      current = Pathname.new(Dir.pwd)

      begin
        @root = current if current.join("Gemfile").exist?
        current = current.parent
      end until current.root?

      @root ||= :none
    end

    def root?
      root != :none
    end

  end
end