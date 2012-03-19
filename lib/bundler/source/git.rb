require "digest/sha1"

module Bundler
  module Source
    class Git < Path
      # The GitProxy is responsible to iteract with git repositories.
      # All actions required by the Git source is encapsualted in this
      # object.
      class GitProxy
        attr_accessor :path, :uri, :ref, :revision

        def initialize(path, uri, ref, revision=nil, &allow)
          @path     = path
          @uri      = uri
          @ref      = ref
          @revision = revision
          @allow    = allow || Proc.new { true }
        end

        def revision
          @revision ||= allowed_in_path { git("rev-parse #{ref}").strip }
        end

        def branch
          @branch ||= allowed_in_path do
            git("branch") =~ /^\* (.*)$/ && $1.strip
          end
        end

        def contains?(commit)
          allowed_in_path do
            result = git_null("branch --contains #{commit}")
            $? == 0 && result =~ /^\* (.*)$/
          end
        end

        def checkout
          if path.exist?
            return if has_revision_cached?
            Bundler.ui.info "Updating #{uri}"
            in_path do
              git %|fetch --force --quiet --tags #{uri_escaped} "refs/heads/*:refs/heads/*"|
            end
          else
            Bundler.ui.info "Fetching #{uri}"
            FileUtils.mkdir_p(path.dirname)
            git %|clone #{uri_escaped} "#{path}" --bare --no-hardlinks|
          end
        end

        def copy_to(destination, submodules=false)
          unless File.exist?(destination.join(".git"))
            FileUtils.mkdir_p(destination.dirname)
            FileUtils.rm_rf(destination)
            git %|clone --no-checkout "#{path}" "#{destination}"|
            File.chmod((0777 & ~File.umask), destination)
          end

          Dir.chdir(destination) do
            git %|fetch --force --quiet --tags "#{path}"|
            git "reset --hard #{@revision}"

            if submodules
              git "submodule init"
              git "submodule update"
            end
          end
        end

      private

        # TODO: Do not rely on /dev/null.
        # Given that open3 is not cross platform until Ruby 1.9.3,
        # the best solution is to pipe to /dev/null if it exists.
        # If it doesn't, everything will work fine, but the user
        # will get the $stderr messages as well.
        def git_null(command)
          if !Bundler::WINDOWS && File.exist?("/dev/null")
            git("#{command} 2>/dev/null", false)
          else
            git(command, false)
          end
        end

        def git(command, check_errors=true)
          if allow?
            out = %x{git #{command}}

            if check_errors && $?.exitstatus != 0
              msg = "Git error: command `git #{command}` in directory #{Dir.pwd} has failed."
              msg << "\nIf this error persists you could try removing the cache directory '#{path}'" if path.exist?
              raise GitError, msg
            end
            out
          else
            raise GitError, "Bundler is trying to run a `git #{command}` at runtime. You probably need to run `bundle install`. However, " \
                            "this error message could probably be more useful. Please submit a ticket at http://github.com/carlhuda/bundler/issues " \
                            "with steps to reproduce as well as the following\n\nCALLER: #{caller.join("\n")}"
          end
        end

        def has_revision_cached?
          return unless @revision
          in_path { git("cat-file -e #{@revision}") }
          true
        rescue GitError
          false
        end

        # Escape the URI for git commands
        def uri_escaped
          if Bundler::WINDOWS
            # Windows quoting requires double quotes only, with double quotes
            # inside the string escaped by being doubled.
            '"' + uri.gsub('"') {|s| '""'} + '"'
          else
            # Bash requires single quoted strings, with the single quotes escaped
            # by ending the string, escaping the quote, and restarting the string.
            "'" + uri.gsub("'") {|s| "'\\''"} + "'"
          end
        end

        def allow?
          @allow.call
        end

        def in_path(&blk)
          checkout unless path.exist?
          Dir.chdir(path, &blk)
        end

        def allowed_in_path
          if allow?
            in_path { yield }
          else
            raise GitError, "The git source #{uri} is not yet checked out. Please run `bundle install` before trying to start your application"
          end
        end
      end

      attr_reader :uri, :ref, :options, :submodules

      def initialize(options)
        @options = options
        @glob = options["glob"] || DEFAULT_GLOB

        @allow_cached = false
        @allow_remote = false

        # Stringify options that could be set as symbols
        %w(ref branch tag revision).each{|k| options[k] = options[k].to_s if options[k] }

        @uri        = options["uri"]
        @ref        = options["ref"] || options["branch"] || options["tag"] || 'master'
        @submodules = options["submodules"]
        @name       = options["name"]
        @version    = options["version"]

        @update     = false
        @installed  = nil
        @local      = false

        if has_app_cache?
          @local = true
          @install_path = @cache_path = app_cache_path
        end
      end

      def self.from_lock(options)
        new(options.merge("uri" => options.delete("remote")))
      end

      def to_lock
        out = "GIT\n"
        out << "  remote: #{@uri}\n"
        out << "  revision: #{revision}\n"
        %w(ref branch tag submodules).each do |opt|
          out << "  #{opt}: #{options[opt]}\n" if options[opt]
        end
        out << "  glob: #{@glob}\n" unless @glob == DEFAULT_GLOB
        out << "  specs:\n"
      end

      def eql?(o)
        Git === o            &&
        uri == o.uri         &&
        ref == o.ref         &&
        name == o.name       &&
        version == o.version &&
        submodules == o.submodules
      end

      alias == eql?

      def to_s
        at = if local?
          path
        elsif options["ref"]
          shortref_for_display(options["ref"])
        else
          ref
        end
        "#{uri} (at #{at})"
      end

      def name
        File.basename(@uri, '.git')
      end

      def install_path
        @install_path ||= begin
          git_scope = "#{base_name}-#{shortref_for_path(revision)}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join(Bundler.ruby_scope).join(git_scope)
          else
            Bundler.install_path.join(git_scope)
          end
        end
      end

      alias :path :install_path

      def unlock!
        git_proxy.revision = nil
      end

      def local_override!(path)
        path = Pathname.new(path)
        path = path.expand_path(Bundler.root) unless path.relative?

        unless options["branch"]
          raise GitError, "Cannot use local override for #{name} at #{path} because " \
            ":branch is not specified in Gemfile. Specify a branch or check " \
            "`bundle config --delete` to remove the local override"
        end

        unless path.exist?
          raise GitError, "Cannot use local override for #{name} because #{path} " \
            "does not exist. Check `bundle config --delete` to remove the local override"
        end

        @local       = true
        @local_specs = nil
        @git_proxy   = GitProxy.new(path, uri, ref)
        @cache_path  = @install_path = path

        if git_proxy.branch != options["branch"]
          raise GitError, "Local override for #{name} at #{path} is using branch " \
            "#{git_proxy.branch} but Gemfile specifies #{options["branch"]}"
        end

        changed = cached_revision && cached_revision != git_proxy.revision

        if changed && !git_proxy.contains?(cached_revision)
          raise GitError, "The Gemfile lock is pointing to revision #{shortref_for_display(cached_revision)} " \
            "but the current branch in your local override for #{name} does not contain such commit. " \
            "Please make sure your branch is up to date."
        end

        changed
      end

      # TODO: actually cache git specs
      def specs(*)
        if requires_checkout? && !@update
          git_proxy.checkout
          git_proxy.copy_to(install_path, submodules)
          @update = true
        end
        local_specs
      end

      def install(spec)
        Bundler.ui.info "Using #{spec.name} (#{spec.version}) from #{to_s} "
        if requires_checkout? && !@installed
          Bundler.ui.debug "  * Checking out revision: #{ref}"
          git_proxy.copy_to(install_path, submodules)
          @installed = true
        end
        generate_bin(spec)
      end

      def cache(spec)
        return if path.expand_path(Bundler.root).to_s.index(Bundler.root.to_s) == 0
        FileUtils.rm_rf(app_cache_path)
        git_proxy.checkout
        git_proxy.copy_to(app_cache_path, @submodules)
        FileUtils.rm_rf(app_cache_path.join(".git"))
      end

      def load_spec_files
        super
      rescue PathError, GitError
        raise GitError, "#{to_s} is not checked out. Please run `bundle install`"
      end

      def cache_path
        @cache_path ||= begin
          git_scope = "#{base_name}-#{uri_hash}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join("cache/git", git_scope)
          else
            Bundler.cache.join("git", git_scope)
          end
        end
      end

    private

      def has_app_cache?
        cached_revision && super
      end

      def app_cache_path
        @app_cache_path ||= Bundler.app_cache.join("#{base_name}-#{shortref_for_path(cached_revision)}")
      end

      def local?
        @local
      end

      def requires_checkout?
        allow_git_ops? && !local?
      end

      def base_name
        File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)?(//\w*/)?(\w*/)*},''),".git")
      end

      def shortref_for_display(ref)
        ref[0..6]
      end

      def shortref_for_path(ref)
        ref[0..11]
      end

      def uri_hash
        if uri =~ %r{^\w+://(\w+@)?}
          # Downcase the domain component of the URI
          # and strip off a trailing slash, if one is present
          input = URI.parse(uri).normalize.to_s.sub(%r{/$},'')
        else
          # If there is no URI scheme, assume it is an ssh/git URI
          input = uri
        end
        Digest::SHA1.hexdigest(input)
      end

      def allow_git_ops?
        @allow_remote || @allow_cached
      end

      def cached_revision
        options["revision"]
      end

      def revision
        git_proxy.revision
      end

      def cached?
        cache_path.exist?
      end

      def git_proxy
        @git_proxy ||= GitProxy.new(cache_path, uri, ref, cached_revision){ allow_git_ops? }
      end

      def generate_bin(spec)
        gem_dir  = Pathname.new(spec.full_gem_path)

        # Some gem authors put absolute paths in their gemspec
        # and we have to save them from themselves
        spec.files = spec.files.map do |p|
          next if File.directory?(p)
          begin
            Pathname.new(p).relative_path_from(gem_dir).to_s
          rescue ArgumentError
            p
          end
        end.compact

        gem_file = Dir.chdir(gem_dir){ Gem::Builder.new(spec).build }

        installer = Path::Installer.new(spec, :env_shebang => false)
        run_hooks(:pre_install, installer)
        installer.build_extensions
        run_hooks(:post_build, installer)
        installer.generate_bin
        run_hooks(:post_install, installer)
      rescue Gem::InvalidSpecificationException => e
        Bundler.ui.warn "\n#{spec.name} at #{spec.full_gem_path} did not have a valid gemspec.\n" \
                        "This prevents bundler from installing bins or native extensions, but " \
                        "that may not affect its functionality."

        if !spec.extensions.empty? && !spec.email.empty?
          Bundler.ui.warn "If you need to use this package without installing it from a gem " \
                          "repository, please contact #{spec.email} and ask them " \
                          "to modify their .gemspec so it can work with `gem build`."
        end

        Bundler.ui.warn "The validation message from Rubygems was:\n  #{e.message}"
      ensure
        Dir.chdir(gem_dir){ FileUtils.rm_rf(gem_file) if gem_file && File.exist?(gem_file) }
      end

      def run_hooks(type, installer)
        hooks_meth = "#{type}_hooks"
        return unless Gem.respond_to?(hooks_meth)
        Gem.send(hooks_meth).each do |hook|
          result = hook.call(installer)
          if result == false
            location = " at #{$1}" if hook.inspect =~ /@(.*:\d+)/
            message = "#{type} hook#{location} failed for #{installer.spec.full_name}"
            raise InstallHookError, message
          end
        end
      end
    end
  end
end
