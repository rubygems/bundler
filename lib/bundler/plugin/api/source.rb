# frozen_string_literal: true
require "uri"
require "digest/sha1"

module Bundler
  module Plugin
    class API
      # This class provides the base to build source plugins
      # All the method here are require to build a source plugin (except
      # `uri_hash`, `gem_install_dir`; they are helpers).
      #
      # Defaults for methods, where ever possible are provided which is
      # expected to work. But, all source plugins have to override
      # `fetch_gemspec_files` and `install`. Defaults are also not provided for
      # `remote!`, `cache!` and `unlock!`.
      #
      # The defaults shall work for most situations but nevertheless they can
      # be (preferably should be) overridden as per the plugins' needs safely
      # (as long as they behave as expected).
      # On overriding `initialize` you should call super first.
      #
      # If required plugin should override `hash`, `==` and `eql?` methods to be
      # able to match objects representing same sources, but may be created in
      # different situation (like form gemfile and lockfile). The default ones
      # checks only for class and uri, but elaborate source plugins may need
      # more comparisons (e.g. git checking on branch or tag).
      #
      # @!attribute [r] uri
      #   @return [String] the remote specified with `source` block in Gemfile
      #
      # @!attribute [r] options
      #   @return [String] options passed during initialization (either from
      #     lockfile or Gemfile)
      #
      # @!attribute [rw] dependency_names
      #   @return [Array<String>] Names of dependencies that the source should
      #     try to resolve. It is not necessary to use this list intenally. This
      #     is present to be compatible with `Definition` and is used by
      #     rubygems source.
      module Source
        attr_reader :uri, :options
        attr_accessor :dependency_names

        def initialize(opts)
          @options = opts
          @dependency_names = []
          @uri = opts["uri"]
          @type = opts["type"]
        end

        # This is used by the default `spec` method to constructs the
        # Specification objects for the gems and versions that can be installed
        # by this source plugin.
        #
        # Note: If the spec method is overridden, this function is not necessary
        #
        # @return [Array<String>] paths of the gemspec files for gems that can
        #                         be installed
        def fetch_gemspec_files
          []
        end

        # Options to be saved in the lockfile so that the source plugin is able
        # to check out same version of gem later.
        #
        # There options are passed when the source plugin is created from the
        # lock file.
        #
        # @return [Hash]
        def options_to_lock
          {}
        end

        # Install the gem specified by the spec at appropriate path.
        # `install_path` provides a sufficient default, if the source can only
        # satisfy one gem,  but is not binding.
        #
        # @return [String] post installation message (if any)
        def install(spec, opts)
          raise MalformattedPlugin, "Source plugins need to override the install method."
        end

        # A default installation path to install a single gem. If the source
        # servers multiple gems, it's not of much use and the source should one
        # of its own.
        def install_path
          @install_path ||=
            begin
              base_name = File.basename(URI.parse(uri).normalize.path)

              gem_install_dir.join("#{base_name}-#{uri_hash[0..11]}")
            end
        end

        # Parses the gemspec files to find the specs for the gems that can be
        # satisfied by the source.
        #
        # Few important points to keep in mind:
        #   - If the gems are not installed then it shall return specs for all
        #   the gems it can satisfy
        #   - If gem is installed (that is to be detected by the plugin itself)
        #   then it shall return at least the specs that are installed.
        #   - The `loaded_from` for each of the specs shall be correct (it is
        #   used to find the load path)
        #
        # @return [Bundler::Index] index containing the specs
        def specs
          files = fetch_gemspec_files

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

        # Set internal representation to fetch the gems/specs from remote.
        def remote!
        end

        # Set internal representation to fetch the gems/specs from cache.
        def cache!
        end

        # This is called to update the spec and installation.
        #
        # If the source plugin is loaded from lockfile or otherwise, it shall
        # refresh the cache/specs (e.g. git sources can make a fresh clone).
        def unlock!
        end

        # This shall check if two source object represent the same source.
        #
        # The comparison shall take place only on the attribute that can be
        # inferred from the options passed from Gemfile and not on attibutes
        # that are used to pin down the gem to specific version (e.g. Git
        # sources should compare on branch and tag but not on commit hash)
        #
        # The sources objects are constructed from Gemfile as well as from
        # lockfile. To converge the sources, it is necessary that they match.
        #
        # The same applies for `eql?` and `hash`
        def ==(other)
          other.is_a?(self.class) && uri == other.uri
        end

        # When overriding `eql?` please preserve the behaviour as mentioned in
        # docstring for `==` method.
        alias_method :eql?, :==

        # When overriding `hash` please preserve the behaviour as mentioned in
        # docstring for `==` method, i.e. two methods equal by above comparison
        # should have same hash.
        def hash
          [self.class, uri].hash
        end

        # A helper method, not necessary if not used internally.
        def installed?
          File.directory?(install_path)
        end

        def unmet_deps
          specs.unmet_dependency_names
        end

        def can_lock?(spec)
          spec.source == self
        end

        def to_lock
          out = String.new("#{LockfileParser::PLUGIN}\n")
          out << "  remote: #{@uri}\n"
          out << "  type: #{@type}\n"
          options_to_lock.each do |opt, value|
            out << "  #{opt}: #{value}\n"
          end
          out << "  specs:\n"
        end

        def to_s
          "plugin source for #{options[:type]} with uri #{uri}"
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
