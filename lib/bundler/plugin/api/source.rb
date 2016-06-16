# frozen_string_literal: true
require "uri"
require "digest/sha1"

module Bundler
  module Plugin
    class API
      module Source
        attr_reader :uri, :options
        attr_accessor :dependency_names

        def initialize(opts)
          @options = opts
          @dependency_names = []
          @uri = opts["uri"]
          @type = opts["type"]
        end

        def installed?
          File.directory?(install_path)
        end

        def fetch_gemfiles
          []
        end

        def options_to_lock
          {}
        end

        def install(spec, opts)
          raise MalformattedPlugin, "Source plugins need to override the install method."
        end

        def install_path
          @install_path ||=
            begin
              base_name = File.basename(URI.parse(uri).normalize.path)

              gem_install_dir.join("#{base_name}-#{uri_hash[0..11]}")
            end
        end

        def specs
          files = fetch_gemfiles

          Bundler::Index.build do |index|
            files.each do |file|
              next unless spec = Bundler.load_gemspec(file)
              Bundler.rubygems.set_installed_by_version(spec)

              spec.source = self
              Bundler.rubygems.validate(spec)

              index << spec
            end
          end
        end

        def remote!
        end

        def cache!
        end

        def ==(other)
          other.is_a?(self.class) && uri == other.uri
        end

        def unmet_deps
          specs.unmet_dependency_names
        end

        def can_lock?(spec)
          spec.source == self
        end

        def to_lock
          out = String.new("PLUGIN\n")
          out << "  remote: #{@uri}\n"
          out << "  type: #{@type}\n"
          options_to_lock.each do |opt, value|
            out << "  #{opt}: #{value}\n"
          end
          out << "  specs:\n"
        end

        def include?(other)
          other == self
        end

        def uri_hash
          Digest::SHA1.hexdigest(uri)
        end

        def gem_install_dir
          Bundler.install_path
        end
      end
    end
  end
end
