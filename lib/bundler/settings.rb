module Bundler
  class Settings
    def initialize(root)
      @root   = root
      @local_config = File.exist?(local_config_file) ? YAML.load_file(local_config_file) : {}
      @global_config = File.exist?(global_config_file) ? YAML.load_file(global_config_file) : {}
    end

    def [](key)
      key = key_for(key)
      @local_config[key] || ENV[key] || @global_config[key]
    end

    def []=(key, value)
      set_key(key, value, @local_config, local_config_file)
    end

    def set_global(key, value)
      set_key(key, value, @global_config, global_config_file)
    end

    def locations(key)
      key = key_for(key)

      locations = {}
      locations[:local]  = @local_config[key]
      locations[:env]    = ENV[key]
      locations[:global] = @global_config[key]
      locations
    end

    def without=(array)
      unless array.empty? && without.empty?
        self[:without] = array.join(":")
      end
    end

    def without
      self[:without] ? self[:without].split(":").map { |w| w.to_sym } : []
    end

    # @local_config["BUNDLE_PATH"] should be prioritized over ENV["BUNDLE_PATH"]
    def path
      path = ENV[key_for(:path)] || @global_config[key_for(:path)]
      return path if path && !@local_config.key?(key_for(:path))

      if path = self[:path]
        "#{path}/#{Bundler.ruby_scope}"
      else
        Gem.dir
      end
    end

  private

    def set_key(key, value, hash, file)
      key = key_for(key)

      unless hash[key] == value
        hash[key] = value
        FileUtils.mkdir_p(file.dirname)
        File.open(file, "w") { |f| f.puts hash.to_yaml }
      end
      value
    end

    def key_for(key)
      "BUNDLE_#{key.to_s.upcase}"
    end

    def global_config_file
      file = ENV["BUNDLE_CONFIG"] || File.join(Gem.user_home, ".bundle/config")
      Pathname.new(file)
    end

    def local_config_file
      Pathname.new("#{@root}/.bundle/config")
    end
  end
end
