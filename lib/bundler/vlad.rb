# Vlad task for Bundler.
#
# Just add "require 'bundler/vlad'" in your Vlad deploy.rb, and
# Bundler will be activated after each new deployment.

namespace :vlad do
  namespace :bundle do
    desc <<-DESC
      Install the current Bundler environment. By default, gems will be \
      installed to the shared/bundle path. Gems in the development and \
      test group will not be installed. The install command is executed \
      with the --deployment and --quiet flags. You can override any of \
      these defaults by setting the variables shown below. If Vlad \
      can not find the 'bundle' cmd then you can override the bundle_cmd \
      variable to specifiy which one it should use.

        set :bundle_gemfile,      "Gemfile"
        set :bundle_dir,          File.join(shared_path, 'bundle')
        set :bundle_flags,        "--deployment --quiet"
        set :bundle_without,      [:development, :test]
        set :bundle_cmd,          "bundle" # e.g. change to "/opt/ruby/bin/bundle"
    DESC
    remote_task :install, :roles => :app do
      bundle_dir     = Rake::RemoteTask.fetch(:bundle_dir, File.join(shared_path, 'bundle'))
      bundle_without = [*Rake::RemoteTask.fetch(:bundle_without, [:development, :test])].compact
      bundle_flags   = Rake::RemoteTask.fetch(:bundle_flags, "--deployment --quiet")
      bundle_gemfile = Rake::RemoteTask.fetch(:bundle_gemfile, "Gemfile")
      bundle_cmd     = Rake::RemoteTask.fetch(:bundle_cmd, "bundle")
      
      args = ["--gemfile #{File.join(current_release, bundle_gemfile)}"]
      args << "--path #{bundle_dir}" unless bundle_dir.to_s.empty?
      args << bundle_flags.to_s
      args << "--without #{bundle_without.join(" ")}" unless bundle_without.empty?
      
      run "#{bundle_cmd} install #{args.join(' ')}"
    end
  end
end
