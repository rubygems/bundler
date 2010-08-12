# Capistrano task for Bundler.
#
# Just add "require 'bundler/capistrano'" in your Capistrano deploy.rb, and Bundler
# will be activated after each new deployment. To configure the directory that
# Bundler will install to, set :bundle_dir before deploy:update_code runs.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy:update_code", "bundle:install"

  namespace :bundle do
    task :install do
      bundle_dir = fetch(:bundle_dir, "#{shared_path}/bundle")
      run "bundle install --gemfile #{release_path}/Gemfile --path #{bundle_dir} --deployment --without development test"
    end
  end
end
