module Bundler
  module PathPreserver
    def self.preserve_path_in_environment(env_var, env = ENV)
      original_env_var      = "_ORIGINAL_#{env_var}"
      original_path         = ENV[original_env_var]
      path                  = ENV[env_var]
      ENV[original_env_var] = path if original_path.nil? || original_path.empty?
      ENV[env_var]          = original_path if path.nil? || path.empty?
    end
  end
end
