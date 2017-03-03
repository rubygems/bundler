# frozen_string_literal: true
require "bundler/cli/common"

module Bundler
  class CLI::Add
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
      @options[:group] = @options[:group].split(",").map(&:strip) if !@options[:group].nil? && !@options[:group].empty?
    end

    def run
      dependency = Bundler::Dependency.new(@gem_name, nil, @options)
      dependency.instance_variable_set(:@requirement, Gem::Requirement.new(@options[:version].split(",").map(&:strip))) unless @options[:version].nil?

      Injector.inject([dependency], :conservative_versioning => @options[:version].nil?) # Perform conservative versioning only when version is not specified
      Installer.install(Bundler.root, Bundler.definition)
    end
  end
end
