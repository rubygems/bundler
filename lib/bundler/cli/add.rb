# frozen_string_literal: true

module Bundler
  class CLI::Add
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
      @options[:group] = @options[:group].split(",").map(&:strip) if !@options[:group].nil? && !@options[:group].empty?
    end

    def run
      raise InvalidOption, "You can not specify `--strict` and `--optimistic` at the same time." if @options[:strict] && @options[:optimistic]

      version = @options[:version].nil? ? nil : @options[:version].split(",").map(&:strip)

      unless version.nil?
        version.each do |v|
          raise InvalidOption, "Invalid gem requirement pattern '#{v}'" unless Gem::Requirement::PATTERN =~ v.to_s
        end
      end
      dependency = Bundler::Dependency.new(@gem_name, version, @options)

      Injector.inject([dependency],
        :conservative_versioning => @options[:version].nil?, # Perform conservative versioning only when version is not specified
        :optimistic => @options[:optimistic],
        :strict => @options[:strict])
      Installer.install(Bundler.root, Bundler.definition) unless @options["skip-install"]
    end
  end
end
