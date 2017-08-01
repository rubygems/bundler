# frozen_string_literal: true

module Bundler
  class LockfileGenerator
    attr_reader :definition
    attr_reader :out

    # @private
    def initialize(definition)
      @definition = definition
      @out = String.new
    end

    def self.generate(definition)
      new(definition).generate!
    end

    def generate!
      add_sources
      add_platforms
      add_dependencies
      add_optional_groups
      add_gemfiles
      add_locked_ruby_version
      add_bundled_with

      out
    end

  private

    def static?
      definition.static_gemfile?
    end

    def add_sources
      definition.send(:sources).lock_sources.each_with_index do |source, idx|
        out << "\n" unless idx.zero?

        # Add the source header
        out << source.to_lock

        # Find all specs for this source
        specs = definition.resolve.select {|s| source.can_lock?(s) }
        add_specs(specs)
      end
    end

    def add_specs(specs)
      # This needs to be sorted by full name so that
      # gems with the same name, but different platform
      # are ordered consistently
      specs.sort_by(&:full_name).each do |spec|
        next if spec.name == "bundler".freeze
        out << spec.to_lock
      end
    end

    def add_platforms
      add_section("PLATFORMS", definition.platforms)
    end

    def add_dependencies
      out << "\nDEPENDENCIES\n"

      handled = []
      definition.dependencies.sort_by(&:to_s).each do |dep|
        next if handled.include?(dep.name)
        handled << dep.name
        out << "  #{dep.name}"
        unless dep.requirement.none?
          reqs = dep.requirement.requirements.map {|o, v| "#{o} #{v}" }.sort.reverse
          out << " (#{reqs.join(", ")})"
        end
        out << "!" if dep.source
        out << "\n"
        next unless static?
        add_value(dep.options_to_lock, 4)
      end
    end

    def add_optional_groups
      return unless static?
      add_section("OPTIONAL GROUPS", definition.optional_groups)
    end

    def add_gemfiles
      return unless static?
      return unless SharedHelpers.md5_available?
      gemfiles = {}
      definition.gemfiles.each do |file|
        md5 = Digest::MD5.file(file).hexdigest
        if file.to_s.start_with?(Bundler.root.to_s)
          file = file.relative_path_from(Bundler.root)
        end
        gemfiles[file] = "md5 #{md5}"
      end
      add_section("GEMFILE CHECKSUMS", gemfiles)
    end

    def add_locked_ruby_version
      return unless locked_ruby_version = definition.locked_ruby_version
      add_section("RUBY VERSION", locked_ruby_version.to_s)
    end

    def add_bundled_with
      add_section("BUNDLED WITH", definition.locked_bundler_version.to_s)
    end

    def add_section(name, value)
      out << "\n#{name}\n"
      add_value(value, 2)
    end

    def add_value(value, indentation)
      indent = " " * indentation
      case value
      when Array
        value.map(&:to_s).sort.each do |val|
          out << "#{indent}#{val}\n"
        end
      when Hash
        value.to_a.sort_by {|k, _| k.to_s }.each do |key, val|
          Array(val).sort.each do |v|
            out << "#{indent}#{key}: #{v}\n"
          end
        end
      when String
        out << "#{indent} #{value}\n"
      else
        raise ArgumentError, "#{value.inspect} can't be serialized in a lockfile"
      end
    end
  end
end
