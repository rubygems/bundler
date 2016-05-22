# frozen_string_literal: true
module Bundler
  class Source
    class Git < Path
      class GitNotInstalledError < GitError
        def initialize
          msg = String.new
          msg << "You need to install git to be able to use gems from git repositories. "
          msg << "For help installing git, please refer to GitHub's tutorial at https://help.github.com/articles/set-up-git"
          super msg
        end
      end

      class GitNotAllowedError < GitError
        def initialize(command)
          msg = String.new
          msg << "Bundler is trying to run a `git #{command}` at runtime. You probably need to run `bundle install`. However, "
          msg << "this error message could probably be more useful. Please submit a ticket at http://github.com/bundler/bundler/issues "
          msg << "with steps to reproduce as well as the following\n\nCALLER: #{caller.join("\n")}"
          super msg
        end
      end

      class GitCommandError < GitError
        def initialize(command, path = nil, extra_info = nil)
          msg = String.new
          msg << "Git error: command `git #{command}` in directory #{SharedHelpers.pwd} has failed."
          msg << "\n#{extra_info}" if extra_info
          msg << "\nIf this error persists you could try removing the cache directory '#{path}'" if path && path.exist?
          super msg
        end
      end

      class GitNotCheckedOutError < GitError
        def initialize(uri)
          super("The git source #{uri} is not yet checked out. Please run `bundle install` before trying to start your application")
        end
      end

      class MissingGitRevisionError < GitError
        def initialize(ref, repo)
          super("Revision #{ref} does not exist in the repository #{repo}. Maybe you misspelled it?")
        end
      end

      # The GitProxy is responsible to interact with git repositories.
      # All actions required by the Git source is encapsulated in this
      # object.
      class GitProxy
        attr_accessor :path, :uri, :ref
        attr_writer :revision

        def initialize(path, uri, ref, revision = nil, git = nil)
          @path     = path
          @uri      = uri
          @ref      = ref
          @revision = revision
          @git      = git
          raise GitNotInstalledError.new if allow? && !Bundler.git_present?
        end

        def revision
          return @revision if @revision

          begin
            @revision ||= find_local_revision
          rescue GitCommandError
            raise MissingGitRevisionError.new(ref, uri)
          end

          @revision
        end

        def branch
          @branch ||= allowed_in_path do
            git("rev-parse --abbrev-ref HEAD").strip
          end
        end

        def contains?(commit)
          allowed_in_path do
            result = git_null("branch --contains #{commit}")
            $? == 0 && result =~ /^\* (.*)$/
          end
        end

        def version
          git("--version").sub("git version", "").strip
        end

        def checkout
          return unless allow_remote?
          if path.exist?
            return if has_revision_cached?
            Bundler.ui.info "Fetching #{URICredentialsFilter.credential_filtered_uri(uri)}"
            in_path do
              git_retry %(fetch --force --quiet --tags #{uri_escaped_with_configured_credentials} "refs/heads/*:refs/heads/*")
            end
          else
            Bundler.ui.info "Fetching #{URICredentialsFilter.credential_filtered_uri(uri)}"
            SharedHelpers.filesystem_access(path.dirname) do |p|
              FileUtils.mkdir_p(p)
            end
            git_retry %(clone #{uri_escaped_with_configured_credentials} "#{path}" --bare --no-hardlinks --quiet)
          end
        end

        def copy_to(destination, submodules = false)
          # method 1
          unless File.exist?(destination.join(".git"))
            begin
              SharedHelpers.filesystem_access(destination.dirname) do |p|
                FileUtils.mkdir_p(p)
              end
              SharedHelpers.filesystem_access(destination) do |p|
                FileUtils.rm_rf(p)
              end
              git_retry %(clone --no-checkout --quiet "#{path}" "#{destination}")
              File.chmod(((File.stat(destination).mode | 0777) & ~File.umask), destination)
            rescue Errno::EEXIST => e
              file_path = e.message[%r{.*?(/.*)}, 1]
              raise GitError, "Bundler could not install a gem because it needs to " \
                "create a directory, but a file exists - #{file_path}. Please delete " \
                "this file and try again."
            end
          end
          # method 2
          SharedHelpers.chdir(destination) do
            git_retry %(fetch --force --quiet --tags "#{path}")
            git "reset --hard #{@revision}"

            git_retry "submodule update --init --recursive" if submodules
          end
        end

      private

        # TODO: Do not rely on /dev/null.
        # Given that open3 is not cross platform until Ruby 1.9.3,
        # the best solution is to pipe to /dev/null if it exists.
        # If it doesn't, everything will work fine, but the user
        # will get the $stderr messages as well.
        def git_null(command)
          git("#{command} 2>#{Bundler::NULL}", false)
        end

        def git_retry(command)
          Bundler::Retry.new("git #{command}", GitNotAllowedError).attempts do
            git(command)
          end
        end

        def git(command, check_errors = true, error_msg = nil)
          command_with_no_credentials = URICredentialsFilter.credential_filtered_string(command, uri)
          raise GitNotAllowedError.new(command_with_no_credentials) unless allow?

          out = SharedHelpers.with_clean_git_env { `git #{command}` }

          stdout_with_no_credentials = URICredentialsFilter.credential_filtered_string(out, uri)
          raise GitCommandError.new(command_with_no_credentials, path, error_msg) if check_errors && !$?.success?
          stdout_with_no_credentials
        end

        def has_revision_cached?
          return unless @revision
          in_path { git("cat-file -e #{@revision}") }
          true
        rescue GitError
          false
        end

        def remove_cache
          FileUtils.rm_rf(path)
        end

        def find_local_revision
          allowed_in_path do
            git("rev-parse --verify #{ref}", true).strip
          end
        end

        # Escape the URI for git commands
        def uri_escaped_with_configured_credentials
          remote = configured_uri_for(uri)
          if Bundler::WINDOWS
            # Windows quoting requires double quotes only, with double quotes
            # inside the string escaped by being doubled.
            '"' + remote.gsub('"') { '""' } + '"'
          else
            # Bash requires single quoted strings, with the single quotes escaped
            # by ending the string, escaping the quote, and restarting the string.
            "'" + remote.gsub("'") { "'\\''" } + "'"
          end
        end

        # Adds credentials to the URI as Fetcher#configured_uri_for does
        def configured_uri_for(uri)
          if /https?:/ =~ uri
            remote = URI(uri)
            config_auth = Bundler.settings[remote.to_s] || Bundler.settings[remote.host]
            remote.userinfo ||= config_auth
            remote.to_s
          else
            uri
          end
        end

        def allow?
          @git ? @git.allow_git_ops? : true
        end

        def allow_remote?
          @git ? @git.allow_git_remote_ops? : true
        end

        def in_path(&blk)
          checkout unless path.exist?
          raise GitNotCheckedOutError.new(uri) unless path.exist?
          SharedHelpers.chdir(path, &blk)
        end

        def allowed_in_path
          return in_path { yield } if allow?
          raise GitNotCheckedOutError.new(uri)
        end
      end
    end
  end
end
