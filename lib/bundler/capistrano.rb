# Capistrano task for Bundler.
#
# Just add "require 'bundler/capistrano'" in your Capistrano deploy file (deploy.rb).
# Bundler will be activated after each new deployment.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy:update_code", "bundler:bundle_new_release"

  namespace :bundler do
    task :create_symlink, :roles => :app do
      set :bundle_dir, File.join(release_path, 'vendor', 'bundle')

      shared_dir = File.join(shared_path, 'bundle')
      run "rm -rf #{bundle_dir}"
      run "mkdir -p #{shared_dir} && ln -s #{shared_dir} #{bundle_dir}"
    end

    task :bundle_new_release, :roles => :app do
      bundler.create_symlink
      run "cd #{release_path} ; bundle install --deployment --without development test"
    end
  end
end
