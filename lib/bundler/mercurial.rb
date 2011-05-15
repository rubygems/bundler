module Bundler
  module Source
    class Mercurial < Path
      attr_reader :uri, :ref, :options

      def initialize(options)
        super

        # stringify options that could be set as symbols
        %w(ref branch tag revision).each{|k| options[k] = options[k].to_s if options[k] }

        @uri        = options["uri"]
        @ref        = options["ref"] || options["branch"] || options["tag"] || 'default'
        @revision   = options["revision"]
        @update     = false
      end

      def self.from_lock(options)
        new(options.merge("uri" => options.delete("remote")))
      end

      def to_lock
        out = "HG\n"
        out << "  remote: #{@uri}\n"
        out << "  revision: #{revision}\n"
        %w(ref branch tag).each do |opt|
          out << "  #{opt}: #{options[opt]}\n" if options[opt]
        end
        out << "  glob: #{@glob}\n" unless @glob == DEFAULT_GLOB
        out << "  specs:\n"
      end

      def eql?(o)
        Mercurial === o      &&
        uri == o.uri         &&
        ref == o.ref         &&
        name == o.name       &&
        version == o.version
      end

      alias == eql?

      def to_s
        sref = options["ref"] ? shortref_for_display(options["ref"]) : ref
        "#{uri} (at #{sref})"
      end

      def name
        File.basename(@uri)
      end

      def path
        @install_path ||= begin
          hg_scope = "#{base_name}-#{shortref_for_path(revision)}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join(Bundler.ruby_scope).join(hg_scope)
          else
            Bundler.install_path.join(hg_scope)
          end
        end
      end

      def unlock!
        @revision = nil
      end

      # TODO: actually cache hg specs
      def specs(*)
        if allow_hg_ops? && !@update
          # Start by making sure the hg cache is up to date
          cache
          checkout
          @update = true
        end
        local_specs
      end

      def install(spec)
        Bundler.ui.info "Using #{spec.name} (#{spec.version}) from #{to_s} "

        unless @installed
          Bundler.ui.debug "  * Checking out revision: #{ref}"
          checkout if allow_hg_ops?
          @installed = true
        end
        generate_bin(spec)
      end

      def load_spec_files
        super
      rescue PathError, GitError
        raise GitError, "#{to_s} is not checked out. Please run `bundle install`"
      end

    private

      def hg(command)
        if allow_hg_ops?
          Bundler.ui.debug("Executing hg #{command}")
          out = %x{hg #{command}}
          Bundler.ui.debug("Output #{out}")

          if $?.exitstatus != 0
            raise GitError, "An error has occurred in hg when running `hg #{command}`. Cannot complete bundling."
          end
          out
        else
          raise GitError, "Bundler is trying to run a `hg #{command}` at runtime. You probably need to run `bundle install`. However, " \
                          "this error message could probably be more useful. Please submit a ticket at http://github.com/carlhuda/bundler/issues " \
                          "with steps to reproduce as well as the following\n\nCALLER: #{caller.join("\n")}"
        end
      end

      def base_name
        File.basename(uri) #this should be enough with hg path style
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

      def cache_path
        @cache_path ||= begin
          hg_scope = "#{base_name}-#{uri_hash}"

          if Bundler.requires_sudo?
            Bundler.user_bundle_path.join("cache/hg", hg_scope)
          else
            Bundler.cache.join("hg", hg_scope)
          end
        end
      end

      def cache
        if cached?
          return if has_revision_cached?
          Bundler.ui.info "Updating #{uri}"
          in_cache do
            hg %|pull -q "#{uri}"|
          end
        else
          Bundler.ui.info "Fetching #{uri}"
          FileUtils.mkdir_p(cache_path.dirname)
          hg %|clone --noupdate "#{uri}" "#{cache_path}"|
        end
      end

      def checkout
        unless File.exist?(path.join(".hg"))
          FileUtils.mkdir_p(path.dirname)
          FileUtils.rm_rf(path)
          hg %|clone --noupdate "#{cache_path}" "#{path}"|
        end
        Dir.chdir(path) do
          hg %|pull "#{cache_path}"|
          hg "update -C #{revision}"
        end
      end

      def has_revision_cached?
        return unless @revision
        in_cache do
          if hg(%|-q log --style=compact|).split("\n").map() { |line| line[-12..13]}.include? @revision
            return true 
          end
        end
        false
      rescue GitError
        false
      end

      def allow_hg_ops?
        @allow_remote || @allow_cached
      end

      def revision
        @revision ||= begin
          if allow_hg_ops?
            in_cache do
              hg("log -r #{ref} --style=default") =~ /\b\d+:(\w{12})$/
              $1
            end
          else
            raise GitError, "The hg source #{uri} is not yet checked out. Please run `bundle install` before trying to start your application"
          end
        end
      end

      def cached?
        cache_path.exist?
      end

      def in_cache(&blk)
        cache unless cached?
        Dir.chdir(cache_path, &blk)
      end

    end
  end
end
