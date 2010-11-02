module Bundler
  class Deployment
    def self.define_task(context, task_method = :task, opts = {})
      if context.is_a?(Capistrano::Configuration)
        context_name = "capistrano"
        role_default = "{:except => {:no_release => true}}"
      else
        context_name = "vlad"
        role_default = "[:app]"
      end

      roles = context.fetch(:bundle_roles, nil)
      opts[:roles] = roles if roles

      context.send :namespace, :bundle do
        send :desc, <<-DESC
          Install the current Bundler environment. By default, gems will be \
          installed to the shared/bundle path. Gems in the development and \
          test group will not be installed. The install command is executed \
          with the --deployment and --quiet flags. If the bundle cmd cannot \
          be found then you can override the bundle_cmd variable to specifiy \
          which one it should use.

          You can override any of these defaults by setting the variables shown below.

          N.B. bundle_roles must be defined before you require 'bundler/#{context_name}' \
          in your deploy.rb file.

            set :bundle_gemfile,  "Gemfile"
            set :bundle_dir,      File.join(fetch(:shared_path), 'bundle')
            set :bundle_flags,    "--deployment --quiet"
            set :bundle_without,  [:development, :test]
            set :bundle_cmd,      "bundle" # e.g. "/opt/ruby/bin/bundle"
            set :bundle_roles,    #{role_default} # e.g. [:app, :batch]
        DESC
        send task_method, :install, opts do
          bundle_cmd     = context.fetch(:bundle_cmd, "bundle")
          bundle_flags   = context.fetch(:bundle_flags, "--deployment --quiet")
          bundle_dir     = context.fetch(:bundle_dir, File.join(context.fetch(:shared_path), 'bundle'))
          bundle_gemfile = context.fetch(:bundle_gemfile, "Gemfile")
          bundle_without = [*context.fetch(:bundle_without, [:development, :test])].compact

          args = ["--gemfile #{File.join(context.fetch(:current_release), bundle_gemfile)}"]
          args << "--path #{bundle_dir}" unless bundle_dir.to_s.empty?
          args << bundle_flags.to_s
          args << "--without #{bundle_without.join(" ")}" unless bundle_without.empty?

          run "#{bundle_cmd} install #{args.join(' ')}"
        end
      end
    end
  end
end
