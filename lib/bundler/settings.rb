module Bundler
  class Settings
    def initialize(root)
      @root          = root
      @local_config  = load_config(local_config_file)
      @global_config = load_config(global_config_file)
    end

    def [](key)
      key = key_for(key)
      @local_config[key] || ENV[key] || @global_config[key]
    end

    def []=(key, value)
      set_key(key, value, @local_config, local_config_file)
    end

    alias :set_local :[]=

    def delete(key)
      @local_config.delete(key_for(key))
    end

    def set_global(key, value)
      set_key(key, value, @global_config, global_config_file)
    end

    def all
      env_keys = ENV.keys.select { |k| k =~ /BUNDLE_.*/ }
      keys = @global_config.keys | @local_config.keys | env_keys

      keys.map do |key|
        key.sub(/^BUNDLE_/, '').gsub(/__/, ".").downcase
      end
    end

    def local_overrides
      repos = {}
      all.each do |k|
        if k =~ /^local\./
          repos[$'] = self[k]
        end
      end
      repos
    end

    def locations(key)
      key = key_for(key)
      locations = {}
      locations[:local]  = @local_config[key] if @local_config.key?(key)
      locations[:env]    = ENV[key] if ENV[key]
      locations[:global] = @global_config[key] if @global_config.key?(key)
      locations
    end

    def pretty_values_for(exposed_key)
      key = key_for(exposed_key)

      locations = []
      if @local_config.key?(key)
        locations << "Set for your local app (#{local_config_file}): #{@local_config[key].inspect}"
      end

      if value = ENV[key]
        locations << "Set via #{key}: #{value.inspect}"
      end

      if @global_config.key?(key)
        locations << "Set for the current user (#{global_config_file}): #{@global_config[key].inspect}"
      end

      return ["You have not configured a value for `#{exposed_key}`"] if locations.empty?
      locations
    end

    def without=(array)
      self[:without] = (array.empty? ? nil : array.join(":")) if array
    end

    def without
      self[:without] ? self[:without].split(":").map { |w| w.to_sym } : []
    end

    # @local_config["BUNDLE_PATH"] should be prioritized over ENV["BUNDLE_PATH"]
    def path
      key  = key_for(:path)
      path = ENV[key] || @global_config[key]
      return path if path && !@local_config.key?(key)

      if path = self[:path]
        "#{path}/#{Bundler.ruby_scope}"
      else
        Bundler.rubygems.gem_dir
      end
    end

    def allow_sudo?
      !@local_config.key?(key_for(:path))
    end

  private
    def key_for(key)
      key = key.to_s.sub(".", "__").upcase
      "BUNDLE_#{key}"
    end

    def set_key(key, value, hash, file)
      key = key_for(key)

      unless hash[key] == value
        hash[key] = value
        hash.delete(key) if value.nil?
        FileUtils.mkdir_p(file.dirname)
        File.open(file, "w") { |f| f.puts hash.to_yaml }
      end
      value
    end

    def global_config_file
      file = ENV["BUNDLE_CONFIG"] || File.join(Bundler.rubygems.user_home, ".bundle/config")
      Pathname.new(file)
    end

    def local_config_file
      Pathname.new("#{@root}/config")
    end

    def load_config(config_file)
      if config_file.exist? && !config_file.size.zero?
        yaml = YAML.load_file(config_file)
      end
      yaml || {}
    end

  end
end
