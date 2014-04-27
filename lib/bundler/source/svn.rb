require 'fileutils'
require 'uri'
require 'digest/sha1'

module Bundler
  class Source

    class SVN < Path
      autoload :SVNProxy, 'bundler/source/svn/svn_proxy'

      attr_reader :uri, :ref, :options

      def initialize(options)
        @options = options
        @glob = options["glob"] || DEFAULT_GLOB

        @allow_cached = false
        @allow_remote = false

        # Stringify options that could be set as symbols
        %w(ref revision).each{|k| options[k] = options[k].to_s if options[k] }

        @uri        = options["uri"]
        @ref        = options["ref"] || 'HEAD'
        @name       = options["name"]
        @version    = options["version"]

        @copied     = false
        @local      = false
      end

      def self.from_lock(options)
        new(options.merge("uri" => options.delete("remote")))
      end

      def to_lock
        out = "SVN\n"
        out << "  remote: #{@uri}\n"
        out << "  revision: #{revision}\n"
        out << "  glob: #{@glob}\n" unless @glob == DEFAULT_GLOB
        out << "  specs:\n"
      end

      def eql?(o)
        o.is_a?(SVN)         &&
        uri == o.uri         &&
        ref == o.ref         &&
        name == o.name       &&
        version == o.version
      end

      alias == eql?

      def to_s
        at = if local?
          path
        elsif options["ref"]
          options["ref"]
        else
          ref
        end
        "#{uri} (at #{at})"
      end

      def name
        File.basename(@uri, '.svn')
      end

      # This is the path which is going to contain a specific
      # checkout of the svn repository. When using local svn
      # repos, this is set to the local repo.
      def install_path
        @install_path ||= begin
          svn_scope = "#{base_name}-#{revision}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join(Bundler.ruby_scope).join(svn_scope)
          else
            Bundler.install_path.join(svn_scope)
          end
        end
      end

      alias :path :install_path

      def extension_dir_name
        "#{base_name}-#{revision}"
      end

      def unlock!
        svn_proxy.revision = nil
        @unlocked = true
      end

      def local_override!(path)
        return false if local?

        path = Pathname.new(path)
        path = path.expand_path(Bundler.root) unless path.relative?

        unless path.exist?
          raise SVNError, "Cannot use local override for #{name} because #{path} " \
            "does not exist. Check `bundle config --delete` to remove the local override"
        end

        set_local!(path)

        # Create a new svn proxy without the cached revision
        # so the Gemfile.lock always picks up the new revision.
        @svn_proxy = SVNProxy.new(path, uri, ref)

        changed = cached_revision && cached_revision != svn_proxy.revision

        if changed && !@unlocked && !svn_proxy.contains?(cached_revision)
          raise SVNError, "The Gemfile lock is pointing to revision #{cached_revision} " \
            "but the current branch in your local override for #{name} does not contain such commit. " \
            "Please make sure your local copy is up to date."
        end

        changed
      end

      # TODO: actually cache svn specs
      def specs(*)
        if has_app_cache? && !local?
          set_local!(app_cache_path)
        end

        if requires_checkout? && !@copied
          svn_proxy.checkout
          svn_proxy.copy_to(install_path)
          serialize_gemspecs_in(install_path)
          @copied = true
        end

        local_specs
      end

      def install(spec)
        debug = nil
        if requires_checkout? && !@copied
          debug = "  * Checking out revision: #{ref}"
          svn_proxy.copy_to(install_path)
          serialize_gemspecs_in(install_path)
          @copied = true
        end
        generate_bin(spec)
        if requires_checkout? && spec.post_install_message
          Installer.post_install_messages[spec.name] = spec.post_install_message
        end
        ["Using #{version_message(spec)} from #{to_s}", nil, debug]
      end

      def cache(spec, custom_path = nil)
        app_cache_path = app_cache_path(custom_path)
        return unless Bundler.settings[:cache_all]
        return if path == app_cache_path
        cached!
        FileUtils.rm_rf(app_cache_path)
        svn_proxy.checkout if requires_checkout?
        svn_proxy.copy_to(app_cache_path)
        serialize_gemspecs_in(app_cache_path)
      end

      def load_spec_files
        super
      rescue PathError => e
        Bundler.ui.trace e
        raise SVNError, "#{to_s} is not yet checked out. Run `bundle install` first."
      end

      # This is the path which is going to contain a cache
      # of the svn repository. When using the same svn repository
      # across different projects, this cache will be shared.
      # When using local svn repos, this is set to the local repo.
      def cache_path
        @cache_path ||= begin
          svn_scope = "#{base_name}-#{uri_hash}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join("cache/svn", svn_scope)
          else
            Bundler.cache.join("svn", svn_scope)
          end
        end
      end

      def app_cache_dirname
        "#{base_name}-#{(cached_revision || revision)}"
      end

      def revision
        svn_proxy.revision
      end

      def allow_svn_ops?
        @allow_remote || @allow_cached
      end

    private

      def serialize_gemspecs_in(destination)
        expanded_path = destination.expand_path(Bundler.root)
        Dir["#{expanded_path}/#{@glob}"].each do |spec_path|
          # Evaluate gemspecs and cache the result. Gemspecs
          # in svn might require svn or other dependencies.
          # The gemspecs we cache should already be evaluated.
          spec = Bundler.load_gemspec(spec_path)
          next unless spec
          File.open(spec_path, 'wb') {|file| file.write(spec.to_ruby) }
        end
      end

      def set_local!(path)
        @local       = true
        @local_specs = @svn_proxy = nil
        @cache_path  = @install_path = path
      end

      def has_app_cache?
        cached_revision && super
      end

      def local?
        @local
      end

      def requires_checkout?
        allow_svn_ops? && !local?
      end

      def base_name
        File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)?(//\w*/)?(\w*/)*},''),".svn")
      end

      def uri_hash
        if uri =~ %r{^\w+://(\w+@)?}
          # Downcase the domain component of the URI
          # and strip off a trailing slash, if one is present
          input = URI.parse(uri).normalize.to_s.sub(%r{/$},'')
        else
          # If there is no URI scheme, assume it is an ssh/svn URI
          input = uri
        end
        Digest::SHA1.hexdigest(input)
      end

      def cached_revision
        options["revision"]
      end

      def cached?
        cache_path.exist?
      end

      def svn_proxy
        @svn_proxy ||= SVNProxy.new(cache_path, uri, ref, cached_revision, self)
      end

    end

  end
end
