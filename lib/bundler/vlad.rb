# Vlad task for Bundler.
#
# Just add "require 'bundler/vlad'" in your Vlad deploy.rb, and
# Bundler will be activated after each new deployment.
require 'bundler/deployment'

namespace :vlad do
  Bundler::Deployment.define_task(Rake::RemoteTask, :remote_task, :roles => :app)
end