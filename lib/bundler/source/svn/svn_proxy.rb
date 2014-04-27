module Bundler
  class Source
    class SVN < Path

      class SVNNotInstalledError < SVNError
        def initialize
          msg =  "You need to install svn to be able to use gems from svn repositories. "
          msg << "For help installing svn, please refer to SVNook's tutorial at http://svnbook.red-bean.com/en/1.7/svn.intro.install.html"
          super msg
        end
      end

      class SVNNotAllowedError < SVNError
        def initialize(command)
          msg =  "Bundler is trying to run a `svn #{command}` at runtime. You probably need to run `bundle install`. However, "
          msg << "this error message could probably be more useful. Please submit a ticket at http://github.com/bundler/bundler/issues "
          msg << "with steps to reproduce as well as the following\n\nCALLER: #{caller.join("\n")}"
          super msg
        end
      end

      class SVNCommandError < SVNError
        def initialize(command, path = nil)
          msg =  "SVN error: command `svn #{command}` in directory #{Dir.pwd} has failed."
          msg << "\nIf this error persists you could try removing the cache directory '#{path}'" if path && path.exist?
          super msg
        end
      end

      # The SVNProxy is responsible to interact with svn repositories.
      # All actions required by the SVN source is encapsulated in this
      # object.
      class SVNProxy
        attr_accessor :path, :uri, :ref
        attr_writer :revision

        def initialize(path, uri, ref, revision = nil, svn = nil)
          @path     = path
          @uri      = uri
          @ref      = ref
          @revision = revision
          @svn      = svn
          raise SVNNotInstalledError.new if allow? && !Bundler.svn_present?
        end

        def revision
          @revision ||= svn("info --revision #{ref} #{uri_escaped} | grep \"Revision\" | awk '{print $2}'").strip
        end

        def contains?(commit)
          revision >= commit
        end

        def checkout
          if path.exist?
            Bundler.ui.confirm "Updating #{uri}"
            in_path do
              svn_retry %|update --force --quiet --revision #{revision}|
            end
          else
            Bundler.ui.info "Fetching #{uri}"
            FileUtils.mkdir_p(path.dirname)
            svn_retry %|checkout --revision #{revision} #{uri_escaped} "#{path}"|
          end
        end

        def copy_to(destination)
          FileUtils.mkdir_p(destination.dirname)
          FileUtils.rm_rf(destination)
          FileUtils.cp_r(path, destination)
          File.chmod((0777 & ~File.umask), destination)
        end

      private

        def svn_retry(command)
          Bundler::Retry.new("svn #{command}", SVNNotAllowedError).attempts do
            svn(command)
          end
        end

        def svn(command, check_errors=true)
          raise SVNNotAllowedError.new(command) unless allow?
          out = %x{svn #{command}}
          raise SVNCommandError.new(command, path) if check_errors && !$?.success?
          out
        end

        # Escape the URI for svn commands
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
          @svn ? @svn.allow_svn_ops? : true
        end

        def in_path(&blk)
          checkout unless path.exist?
          SharedHelpers.chdir(path, &blk)
        end
      end

    end
  end
end
