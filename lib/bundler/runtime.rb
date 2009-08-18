require "bundler/dependency"

module Bundler
  class ManifestFileNotFound < StandardError; end

  def self.require(environment = nil)
    ManifestBuilder.run(@gemfile, environment || :default)
  end

  class ManifestBuilder
    def self.run(gemfile, environment)
      unless File.exist?(gemfile)
        raise ManifestFileNotFound, "#{gemfile.inspect} does not exist"
      end

      builder = new(environment)
      builder.instance_eval(File.read(gemfile))
      builder
    end

    def initialize(environment)
      @environment = environment
    end

    def bundle_path(*) ; end

    def bin_path(*) ; end

    def disable_rubygems(*) ; end

    def disable_system_gems(*) ; end

    def source(*) ; end

    def clear_sources(*) ; end

    def gem(name, *args, &blk)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      dep = Dependency.new(name, options.merge(:version => version), &blk)
      dep.require(@environment)
      dep
    end
  end
end