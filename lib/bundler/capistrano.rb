# Capistrano task for Bundler.
#
# Just add "require 'bundler/capistrano'" in your Capistrano deploy.rb, and
# Bundler will be activated after each new deployment.
require 'bundler/deployment'

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy:update_code", "bundle:install"

  bundle_roles = self[:bundle_roles]
  opts = {:except => { :no_release => true }}
  opts[:roles] = bundle_roles if bundle_roles

  Bundler::Deployment.define_task(self, :task, opts)
end
