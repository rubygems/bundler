module Bundler
  module Source

    class Git < Path
      # The GitProxy is responsible to iteract with git repositories.
      # All actions required by the Git source is encapsualted in this
      # object.
      class GitProxy
        attr_accessor :path, :uri, :ref, :password
        attr_writer :revision

        def initialize(path, uri, ref, revision=nil, password=nil, &allow)
          @path     = path
          @uri      = uri
          @ref      = ref
          @revision = revision
          @password = password
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
            clone_command = %|clone #{uri_escaped} "#{path}" --bare --no-hardlinks|
            clone_command = "#{clone_command} --quiet" if Bundler.ui.quiet?
            git clone_command
          end
        end

        def copy_to(destination, submodules=false)
          unless File.exist?(destination.join(".git"))
            FileUtils.mkdir_p(destination.dirname)
            FileUtils.rm_rf(destination)
            git %|clone --no-checkout "#{path}" "#{destination}"|
            File.chmod((0777 & ~File.umask), destination)
          end

          SharedHelpers.chdir(destination) do
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
            # If a password is set and ssh_auth is supported, use SSH_ASKPASS.
            out = if @password.nil? or not ssh_auth_supported?
              %x{git #{command}}
            else
              ssh_auth command
            end

            if check_errors && $?.exitstatus != 0
              msg = "Git error: command `git #{command}` in directory #{Dir.pwd} has failed."
              msg << "\nIf this error persists you could try removing the cache directory '#{path}'" if path.exist?
              raise GitError, msg
            end
            out
          else
            raise GitError, "Bundler is trying to run a `git #{command}` at runtime. You probably need to run `bundle install`. However, " \
                            "this error message could probably be more useful. Please submit a ticket at http://github.com/bundler/bundler/issues " \
                            "with steps to reproduce as well as the following\n\nCALLER: #{caller.join("\n")}"
          end
        end

        def ssh_auth_supported?
          not Bundler::WINDOWS
        end

        def ssh_auth(command)
          file     = Tempfile.new(['ssh-auth', '.rb'])
          out      = nil
          ruby_bin = "#{RbConfig::CONFIG['bindir']}/#{RbConfig::CONFIG['ruby_install_name']}"
          begin
            file.write %{#!#{ruby_bin}
              if not ENV['SSH_ASKPASS_PASSWORD'].nil?
                print ENV['SSH_ASKPASS_PASSWORD']
              else
                ENV['SSH_ASKPASS']          = File.expand_path $0
                ENV['SSH_ASKPASS_PASSWORD'] = ENV['ssh_password']
                ENV['DISPLAY']              = 'dummydisplay:0' if ENV['DISPLAY'].nil?
                pid = fork do
                  Process.setsid
                  exec ARGV.join ' '
                end
                Process.waitpid pid
              end
            }
            file.close
            File.chmod 0500, file.path
            out = %x{ssh_password='#{@password}' #{file.path} git #{command}}
          ensure
            file.close
            file.unlink
          end
          out
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
          SharedHelpers.chdir(path, &blk)
        end

        def allowed_in_path
          if allow?
            in_path { yield }
          else
            raise GitError, "The git source #{uri} is not yet checked out. Please run `bundle install` before trying to start your application"
          end
        end

      end

    end
  end
end
