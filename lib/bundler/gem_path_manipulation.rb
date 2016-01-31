module Bundler
  def self.preserve_gem_path
    original_gem_path = ENV["_ORIGINAL_GEM_PATH"]
    gem_path          = ENV["GEM_PATH"]
    ENV["_ORIGINAL_GEM_PATH"] = gem_path          if original_gem_path.nil? || original_gem_path == ""
    ENV["GEM_PATH"]           = original_gem_path if gem_path.nil? || gem_path == ""
  end

  def self.preserve_path
    original_path         = ENV["_ORIGINAL_PATH"]
    path                  = ENV["PATH"]
    ENV["_ORIGINAL_PATH"] = path          if original_path.nil? || original_path == ""
    ENV["PATH"]           = original_path if path.nil? || path == ""
  end
end
