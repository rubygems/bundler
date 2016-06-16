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

        def specs
          index = Bundler::Index.new

          files = fetch_gemfiles
          files.each do |file|
            next unless spec = Bundler.load_gemspec(file)
            spec.source = self
            Bundler.rubygems.set_installed_by_version(spec)
            # Validation causes extension_dir to be calculated, which depends
            # on #source, so we validate here instead of load_gemspec
            Bundler.rubygems.validate(spec)

            index << spec
          end

          index
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

        def install(spec, opts)
          raise MalformattedPlugin, "Source plugins need to override the install method."
        end

        def fetch_gemfiles
          []
        end

        def options_to_lock
          {}
        end

        def remote!
        end

        def cache!
        end

        def include?(other)
          other == self
        end

        def ==(other)
          other.is_a?(self.class) && uri == other.uri
        end

        def uri_hash
          Digest::SHA1.hexdigest(uri)
        end

        def gem_install_dir
          Bundler.install_path
        end

        def install_path
          @install_path ||=
            begin
              base_name = File.basename(URI.parse(uri).normalize.path)

              gem_install_dir.join("#{base_name}-#{uri_hash[0..11]}")
            end
        end

        def installed?
          File.directory?(install_path)
        end
      end
    end
  end
end
