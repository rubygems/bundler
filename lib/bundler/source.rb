require "uri"
require 'rubygems/user_interaction'
require "rubygems/installer"
require "rubygems/spec_fetcher"
require "rubygems/format"
require "digest/sha1"
require "fileutils"

module Bundler
  module Source
    # TODO: Refactor this class
    class Rubygems
      FORCE_MODERN_INDEX_LIMIT = 100 # threshold for switching back to the modern index instead of fetching every spec

      attr_reader :remotes, :caches
      attr_accessor :dependency_names

      def initialize(options = {})
        @options = options
        @remotes = (options["remotes"] || []).map { |r| normalize_uri(r) }
        @fetchers = {}
        @allow_remote = false
        @allow_cached = false

        @caches = [ Bundler.app_cache ] +
          Bundler.rubygems.gem_path.map{|p| File.expand_path("#{p}/cache") }
      end

      def remote!
        @allow_remote = true
      end

      def cached!
        @allow_cached = true
      end

      def hash
        Rubygems.hash
      end

      def eql?(o)
        Rubygems === o
      end

      alias == eql?

      def options
        { "remotes" => @remotes.map { |r| r.to_s } }
      end

      def self.from_lock(options)
        s = new(options)
        Array(options["remote"]).each { |r| s.add_remote(r) }
        s
      end

      def to_lock
        out = "GEM\n"
        out << remotes.map {|r| "  remote: #{r}\n" }.join
        out << "  specs:\n"
      end

      def to_s
        remote_names = self.remotes.map { |r| r.to_s }.join(', ')
        "rubygems repository #{remote_names}"
      end
      alias_method :name, :to_s

      def specs
        @specs ||= fetch_specs
      end

      def install(spec)
        if installed_specs[spec].any?
          Bundler.ui.info "Using #{spec.name} (#{spec.version}) "
          return
        end

        Bundler.ui.info "Installing #{spec.name} (#{spec.version}) "
        path = cached_gem(spec)
        if Bundler.requires_sudo?
          install_path = Bundler.tmp
          bin_path     = install_path.join("bin")
        else
          install_path = Bundler.rubygems.gem_dir
          bin_path     = Bundler.system_bindir
        end

        Bundler.rubygems.preserve_paths do
          Bundler::GemInstaller.new(path,
            :install_dir         => install_path.to_s,
            :bin_dir             => bin_path.to_s,
            :ignore_dependencies => true,
            :wrappers            => true,
            :env_shebang         => true
          ).install
        end

        if spec.post_install_message
          Installer.post_install_messages[spec.name] = spec.post_install_message
        end

        # SUDO HAX
        if Bundler.requires_sudo?
          Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/gems"
          Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/specifications"
          Bundler.sudo "cp -R #{Bundler.tmp}/gems/#{spec.full_name} #{Bundler.rubygems.gem_dir}/gems/"
          Bundler.sudo "cp -R #{Bundler.tmp}/specifications/#{spec.full_name}.gemspec #{Bundler.rubygems.gem_dir}/specifications/"
          spec.executables.each do |exe|
            Bundler.mkdir_p Bundler.system_bindir
            Bundler.sudo "cp -R #{Bundler.tmp}/bin/#{exe} #{Bundler.system_bindir}"
          end
        end

        spec.loaded_from = "#{Bundler.rubygems.gem_dir}/specifications/#{spec.full_name}.gemspec"
      end

      def cache(spec)
        cached_path = cached_gem(spec)
        raise GemNotFound, "Missing gem file '#{spec.full_name}.gem'." unless cached_path
        return if File.dirname(cached_path) == Bundler.app_cache.to_s
        Bundler.ui.info "  * #{File.basename(cached_path)}"
        FileUtils.cp(cached_path, Bundler.app_cache)
      end

      def add_remote(source)
        @remotes << normalize_uri(source)
      end

      def replace_remotes(source)
        return false if source.remotes == @remotes

        @remotes = []
        source.remotes.each do |r|
          add_remote r.to_s
        end

        true
      end

    private

      def cached_gem(spec)
        possibilities = @caches.map { |p| "#{p}/#{spec.file_name}" }
        cached_gem = possibilities.find { |p| File.exist?(p) }
        unless cached_gem
          raise Bundler::GemNotFound, "Could not find #{spec.file_name} for installation"
        end
        cached_gem
      end

      def normalize_uri(uri)
        uri = uri.to_s
        uri = "#{uri}/" unless uri =~ %r'/$'
        uri = URI(uri)
        raise ArgumentError, "The source must be an absolute URI" unless uri.absolute?
        uri
      end

      def fetch_specs
        # remote_specs usually generates a way larger Index than the other
        # sources, and large_idx.use small_idx is way faster than
        # small_idx.use large_idx.
        if @allow_remote
          idx = remote_specs.dup
        else
          idx = Index.new
        end
        idx.use(cached_specs, :override_dupes) if @allow_cached || @allow_remote
        idx.use(installed_specs, :override_dupes)
        idx
      end

      def installed_specs
        @installed_specs ||= begin
          idx = Index.new
          have_bundler = false
          Bundler.rubygems.all_specs.reverse.each do |spec|
            next if spec.name == 'bundler' && spec.version.to_s != VERSION
            have_bundler = true if spec.name == 'bundler'
            spec.source = self
            idx << spec
          end

          # Always have bundler locally
          unless have_bundler
           # We're running bundler directly from the source
           # so, let's create a fake gemspec for it (it's a path)
           # gemspec
           bundler = Gem::Specification.new do |s|
             s.name     = 'bundler'
             s.version  = VERSION
             s.platform = Gem::Platform::RUBY
             s.source   = self
             s.authors  = ["bundler team"]
             s.loaded_from = File.expand_path("..", __FILE__)
           end
           idx << bundler
          end
          idx
        end
      end

      def cached_specs
        @cached_specs ||= begin
          idx = installed_specs.dup

          path = Bundler.app_cache
          Dir["#{path}/*.gem"].each do |gemfile|
            next if gemfile =~ /^bundler\-[\d\.]+?\.gem/

            begin
              s ||= Bundler.rubygems.spec_from_gem(gemfile)
            rescue Gem::Package::FormatError
              raise GemspecError, "Could not read gem at #{gemfile}. It may be corrupted."
            end

            s.source = self
            idx << s
          end
        end

        idx
      end

      def remote_specs
        @remote_specs ||= begin
          idx     = Index.new
          old     = Bundler.rubygems.sources

          sources = {}
          remotes.each do |uri|
            fetcher          = Bundler::Fetcher.new(uri)
            specs            = fetcher.specs(dependency_names, self)
            sources[fetcher] = specs.size

            idx.use specs
          end

          # don't need to fetch all specifications for every gem/version on
          # the rubygems repo if there's no api endpoints to search over
          # or it has too many specs to fetch
          fetchers              = sources.keys
          api_fetchers          = fetchers.select {|fetcher| fetcher.has_api }
          modern_index_fetchers = fetchers - api_fetchers
          if api_fetchers.any? && modern_index_fetchers.all? {|fetcher| sources[fetcher] < FORCE_MODERN_INDEX_LIMIT }
            # this will fetch all the specifications on the rubygems repo
            unmet_dependency_names = idx.unmet_dependency_names
            unmet_dependency_names -= ['bundler'] # bundler will always be unmet

            Bundler.ui.debug "Unmet Dependencies: #{unmet_dependency_names}"
            if unmet_dependency_names.any?
              api_fetchers.each do |fetcher|
                idx.use fetcher.specs(unmet_dependency_names, self)
              end
            end
          else
            Bundler::Fetcher.disable_endpoint = true
            api_fetchers.each {|fetcher| idx.use fetcher.specs([], self) }
          end

          idx
        ensure
          Bundler.rubygems.sources = old
        end
      end
    end


    class Path
      class Installer < Bundler::GemInstaller
        def initialize(spec, options = {})
          @spec              = spec
          @bin_dir           = Bundler.requires_sudo? ? "#{Bundler.tmp}/bin" : "#{Bundler.rubygems.gem_dir}/bin"
          @gem_dir           = Bundler.rubygems.path(spec.full_gem_path)
          @wrappers          = options[:wrappers] || true
          @env_shebang       = options[:env_shebang] || true
          @format_executable = options[:format_executable] || false
        end

        def generate_bin
          return if spec.executables.nil? || spec.executables.empty?

          if Bundler.requires_sudo?
            FileUtils.mkdir_p("#{Bundler.tmp}/bin") unless File.exist?("#{Bundler.tmp}/bin")
          end
          super
          if Bundler.requires_sudo?
            Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/bin"
            spec.executables.each do |exe|
              Bundler.sudo "cp -R #{Bundler.tmp}/bin/#{exe} #{Bundler.rubygems.gem_dir}/bin/"
            end
          end
        end
      end

      attr_reader   :path, :options
      attr_writer   :name
      attr_accessor :version

      DEFAULT_GLOB = "{,*,*/*}.gemspec"

      def initialize(options)
        @options = options
        @glob = options["glob"] || DEFAULT_GLOB

        @allow_cached = false
        @allow_remote = false

        if options["path"]
          @path = Pathname.new(options["path"])
          @path = @path.expand_path(Bundler.root) unless @path.relative?
        end

        @name    = options["name"]
        @version = options["version"]

        # Stores the original path. If at any point we move to the
        # cached directory, we still have the original path to copy from.
        @original_path = @path
      end

      def remote!
        @allow_remote = true
      end

      def cached!
        @allow_cached = true
      end

      def self.from_lock(options)
        new(options.merge("path" => options.delete("remote")))
      end

      def to_lock
        out = "PATH\n"
        out << "  remote: #{relative_path}\n"
        out << "  glob: #{@glob}\n" unless @glob == DEFAULT_GLOB
        out << "  specs:\n"
      end

      def to_s
        "source at #{@path}"
      end

      def hash
        self.class.hash
      end

      def eql?(o)
        o.instance_of?(Path) &&
        path.expand_path(Bundler.root) == o.path.expand_path(Bundler.root) &&
        version == o.version
      end

      alias == eql?

      def name
        File.basename(path.expand_path(Bundler.root).to_s)
      end

      def install(spec)
        Bundler.ui.info "Using #{spec.name} (#{spec.version}) from #{to_s} "
        # Let's be honest, when we're working from a path, we can't
        # really expect native extensions to work because the whole point
        # is to just be able to modify what's in that path and go. So, let's
        # not put ourselves through the pain of actually trying to generate
        # the full gem.
        Installer.new(spec).generate_bin
      end

      def cache(spec)
        return unless Bundler.settings[:cache_all]
        return if @original_path.expand_path(Bundler.root).to_s.index(Bundler.root.to_s) == 0
        FileUtils.rm_rf(app_cache_path)
        FileUtils.cp_r("#{@original_path}/.", app_cache_path)
        FileUtils.touch(app_cache_path.join(".bundlecache"))
      end

      def local_specs(*)
        @local_specs ||= load_spec_files
      end

      def specs
        if has_app_cache?
          @path = app_cache_path
        end
        local_specs
      end

      def app_cache_dirname
        name
      end

    private

      def app_cache_path
        @app_cache_path ||= Bundler.app_cache.join(app_cache_dirname)
      end

      def has_app_cache?
        SharedHelpers.in_bundle? && app_cache_path.exist?
      end

      def load_spec_files
        index = Index.new
        expanded_path = path.expand_path(Bundler.root)

        if File.directory?(expanded_path)
          Dir["#{expanded_path}/#{@glob}"].each do |file|
            spec = Bundler.load_gemspec(file)
            if spec
              spec.loaded_from = file.to_s
              spec.source = self
              index << spec
            end
          end

          if index.empty? && @name && @version
            index << Gem::Specification.new do |s|
              s.name     = @name
              s.source   = self
              s.version  = Gem::Version.new(@version)
              s.platform = Gem::Platform::RUBY
              s.summary  = "Fake gemspec for #{@name}"
              s.relative_loaded_from = "#{@name}.gemspec"
              s.authors  = ["no one"]
              if expanded_path.join("bin").exist?
                executables = expanded_path.join("bin").children
                executables.reject!{|p| File.directory?(p) }
                s.executables = executables.map{|c| c.basename.to_s }
              end
            end
          end
        else
          raise PathError, "The path `#{expanded_path}` does not exist."
        end

        index
      end

      def relative_path
        if path.to_s.match(%r{^#{Regexp.escape Bundler.root.to_s}})
          return path.relative_path_from(Bundler.root)
        end
        path
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
              git "submodule update --init --recursive"
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

      attr_reader :uri, :ref, :branch, :options, :submodules

      def initialize(options)
        @options = options
        @glob = options["glob"] || DEFAULT_GLOB

        @allow_cached = false
        @allow_remote = false

        # Stringify options that could be set as symbols
        %w(ref branch tag revision).each{|k| options[k] = options[k].to_s if options[k] }

        @uri        = options["uri"]
        @branch     = options["branch"]
        @ref        = options["ref"] || options["branch"] || options["tag"] || 'master'
        @submodules = options["submodules"]
        @name       = options["name"]
        @version    = options["version"]

        @update     = false
        @installed  = nil
        @local      = false
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
        branch == o.branch   &&
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

      # This is the path which is going to contain a specific
      # checkout of the git repository. When using local git
      # repos, this is set to the local repo.
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
        return false if local?

        path = Pathname.new(path)
        path = path.expand_path(Bundler.root) unless path.relative?

        unless options["branch"] || Bundler.settings[:disable_local_branch_check]
          raise GitError, "Cannot use local override for #{name} at #{path} because " \
            ":branch is not specified in Gemfile. Specify a branch or use " \
            "`bundle config --delete` to remove the local override"
        end

        unless path.exist?
          raise GitError, "Cannot use local override for #{name} because #{path} " \
            "does not exist. Check `bundle config --delete` to remove the local override"
        end

        set_local!(path)

        # Create a new git proxy without the cached revision
        # so the Gemfile.lock always picks up the new revision.
        @git_proxy = GitProxy.new(path, uri, ref)

        if git_proxy.branch != options["branch"] && !Bundler.settings[:disable_local_branch_check]
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
        if has_app_cache? && !local?
          set_local!(app_cache_path)
        end

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
        return unless Bundler.settings[:cache_all]
        return if path == app_cache_path
        cached!
        FileUtils.rm_rf(app_cache_path)
        git_proxy.checkout if requires_checkout?
        git_proxy.copy_to(app_cache_path, @submodules)
        FileUtils.rm_rf(app_cache_path.join(".git"))
        FileUtils.touch(app_cache_path.join(".bundlecache"))
      end

      def load_spec_files
        super
      rescue PathError, GitError
        raise GitError, "#{to_s} is not checked out. Please run `bundle install`"
      end

      # This is the path which is going to contain a cache
      # of the git repository. When using the same git repository
      # across different projects, this cache will be shared.
      # When using local git repos, this is set to the local repo.
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

      def app_cache_dirname
        "#{base_name}-#{shortref_for_path(cached_revision || revision)}"
      end

    private

      def set_local!(path)
        @local       = true
        @local_specs = @git_proxy = nil
        @cache_path  = @install_path = path
      end

      def has_app_cache?
        cached_revision && super
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
    end
  end
end
