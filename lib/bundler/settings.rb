module Bundler
  class Settings
    def initialize(root)
      @root   = root
      load_config_files
    end

    def [](key)
      key = key_for(key)
      @local_config[key] || ENV[key] || @global_config[key]
    end

    def []=(key, value)
      set_key(key, value, @local_config, local_config_file)
    end

    def delete(key)
      @local_config
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

    def locations(key)
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
      unless array.empty?
        self[:without] = array.join(":")
      end
    end

    def without
      self[:without] ? self[:without].split(":").map { |w| w.to_sym } : []
    end

    # @local_config["BUNDLE_PATH"] should be prioritized over ENV["BUNDLE_PATH"]
    def path
      return install_path if install_path?
      path = ENV[key_for(:path)] || @global_config[key_for(:path)]
      return path if path && !@local_config.key?(key_for(:path))
      if path = self[:path]
        "#{path}/#{Bundler.ruby_scope}"
      else
        Gem.dir
      end
    end

    def install_path?
      Bundler.settings.all.each do |set|
      end
      if Bundler.settings[:install_path]
        true
      else
        false
      end
    end

    # @local_config["BUNDLE_INSTALL_PATH"] should be prioritized over ENV["BUNDLE_INSTALL_PATH"]
    def install_path
      load_config_files
      ipath = ENV[key_for(:install_path)] || @global_config[key_for(:install_path)] #if self.install_path?
      return ipath if ipath && !@local_config.key?(key_for(:install_path))
      if Bundler.settings[:install_path] #&& !ipath.nil?
        ipath || Bundler.settings[:install_path]
      else
        Gem.dir
      end
    end

    def cli
      @cli = ::Bundler::CLI.new
      @cli
    end

    def allow_sudo?
      !@local_config.key?(key_for(:path))
    end

  private
    def key_for(key)
      key = key.to_s.sub(".", "__").upcase.sub("-", "_")
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
      file = ENV["BUNDLE_CONFIG"] || File.join(Gem.user_home, ".bundle/config")
      Pathname.new(file)
    end

    def local_config_file
      Pathname.new("#{@root}/config")
    end

    def load_config_files
      @local_config = File.exist?(local_config_file) ? YAML.load_file(local_config_file) : {}
      @global_config = File.exist?(global_config_file) ? YAML.load_file(global_config_file) : {}
    end
  end
end
