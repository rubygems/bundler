# Capistrano task for Bundler.
#
# Just add "require 'bundler/capistrano'" in your Capistrano deploy.rb, and
# Bundler will be activated after each new deployment.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy:update_code", "bundle:install"

  namespace :bundle do
    desc <<-DESC
      Install the current Bundler environment. By default, gems will be \
      installed to the shared/bundle path. However, you can specify a \
      different directory via the bundle_dir variable. You can also specify \
      the file name and path to the Gemfile using the bundle_gemfile \
      variable. By default, gems in the development and test group will not \
      be installed. If you want these gems to be installed or want \
      additional named groups to be excluded, you can specify the \
      bundle_without variable

        set :bundle_gemfile, "Gemfile"
        set :bundle_dir,     "vendor/bundle"
        set :bundle_without, [:development, :test]
    DESC
    task :install, :except => { :no_release => true } do
      bundle_dir         = fetch(:bundle_dir,         "#{fetch(:shared_path)}/bundle")
      bundle_without     = [*fetch(:bundle_without,   [:development, :test])].compact
      bundle_install_env = fetch(:bundle_install_env, "--deployment")
      bundle_gemfile     = fetch(:bundle_gemfile,     "Gemfile")
      args = [
        "--gemfile #{fetch(:latest_release)}/#{bundle_gemfile}",
        ("--path #{bundle_dir}" unless bundle_dir.to_s.empty?),
        "#{bundle_install_env}",
        ("--without #{bundle_without.join(" ")}" unless bundle_without.empty?)
      ].compact
      run "bundle install #{args.join(' ')}"
    end
  end
end
