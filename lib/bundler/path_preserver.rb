module Bundler
  module PathPreserver
    def self.preserve_path_in_environment(env_var, env)
      original_env_var      = "_ORIGINAL_#{env_var}"
      original_path         = env[original_env_var]
      path                  = env[env_var]
      env[original_env_var] = path if original_path.nil? || original_path.empty?
      env[env_var]          = original_path if path.nil? || path.empty?
    end
  end
end
