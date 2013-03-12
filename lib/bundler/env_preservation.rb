require "base64"

module Bundler
  def self.preserve_original_environment
    original_env_data = ENV["_BUNDLER_ORIGINAL_ENV"]
    # We are the outer environment.
    if original_env_data.nil? || original_env_data == ""
      const_set(:ORIGINAL_ENV, ENV.to_hash)

      # Avoids a dependency on JSON or similar, or inventing our own.
      ENV["_BUNDLER_ORIGINAL_ENV"] = Base64.encode64(Marshal.dump(ORIGINAL_ENV))
      return
    end

    # Inner environment: restore as needed
    begin
      original_env = Marshal.load(Base64.decode64(original_env_data))
    rescue StandardError => error
      raise RuntimeError, "_BUNDLER_ORIGINAL_ENV appears to be corrupt: #{error}"
    end

    # To support with_original_env and friends.
    const_set(:ORIGINAL_ENV, original_env)

    gem_path        = ENV["GEM_PATH"]
    ENV["GEM_PATH"] = ORIGINAL_ENV["GEM_PATH"] if gem_path.nil? || gem_path == ""
  end
end
