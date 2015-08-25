require "uri"

module Bundler
  class Settings
    BOOL_KEYS = %w(frozen cache_all no_prune disable_local_branch_check ignore_messages gem.mit gem.coc).freeze
    NUMBER_KEYS = %w(retry timeout redirect).freeze
    DEFAULT_CONFIG = { :retry => 3, :timeout => 10, :redirect => 5 }

    attr_reader :root

    def initialize(root = nil)
      @root           = root
      @current_config ||= {}
      @local_config   = load_config(local_config_file)
      @global_config  = load_config(global_config_file)
    end

    def [](name)
      key = key_for(name)
      value = (@current_config[key] || @local_config[key] || ENV[key] || @global_config[key] || DEFAULT_CONFIG[name])
      case
      when value.nil?
        nil
      when is_bool(name) || value == "false"
        to_bool(value)
      when is_num(name)
        value.to_i
      else
        value
      end
    end

    def set_current(key, value)
      @current_config[key_for(key)] = value
    end

    alias_method :[]=, :set_current

    def set_local(key, value)
      local_config_file or raise GemfileNotFound, "Could not locate #{SharedHelpers.gemfile_name}"
      set_key(key, value, @local_config, local_config_file)
    end

    def delete(key)
      @local_config.delete(key_for(key))
    end

    def set_global(key, value)
      set_key(key, value, @global_config, global_config_file)
    end

    def all
      env_keys = ENV.keys.select {|k| k =~ /BUNDLE_.*/ }

      keys = @current_config.keys | @global_config.keys | @local_config.keys | env_keys

      keys.map do |key|
        key.sub(/^BUNDLE_/, "").gsub(/__/, ".").downcase
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

    def mirror_for(uri)
      uri = URI(uri.to_s) unless uri.is_a?(URI)

      # Settings keys are all downcased
      normalized_key = normalize_uri(uri.to_s.downcase)
      gem_mirrors[normalized_key] || uri
    end

    def credentials_for(uri)
      self[uri.to_s] || self[uri.host]
    end

    def gem_mirrors
      all.inject({}) do |h, k|
        if k =~ /^mirror\./
          uri = normalize_uri($')
          h[uri] = normalize_uri(self[k])
        end
        h
      end
    end

    def locations(key)
      key = key_for(key)
      locations = {}
      locations[:current] = @current_config[key] if @current_config.key?(key)
      locations[:local]   = @local_config[key] if @local_config.key?(key)
      locations[:env]     = ENV[key] if ENV[key]
      locations[:global]  = @global_config[key] if @global_config.key?(key)
      locations[:default] = DEFAULT_CONFIG[key] if DEFAULT_CONFIG.key?(key)
      locations
    end

    def pretty_values_for(exposed_key)
      key = key_for(exposed_key)

      locations = []
      if @current_config.key?(key)
        locations << "Set only for this command with a flag: #{@current_config[key].inspect}"
      end

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

    def without=(array, scope = :current)
      set_array(:without, array, scope)
    end

    def with=(array, scope = :current)
      set_array(:with, array, scope)
    end

    # Finds the previously set `without` groups in the given scope.
    #
    # @param  [Symbol,Nil] scope
    #         any of `:global`, `:local`, or `nil`.
    #
    # @return [Array<Symbol>] The previously set `without` groups.
    #
    def without(scope = nil)
      groups_array(:without, scope)
    end

    # Finds the previously set `with` groups in the given scope.
    #
    # @param  [Symbol,Nil] scope
    #         any of `:global`, `:local`, or `nil`.
    #
    # @return [Array<Symbol>] The previously set `with` groups.
    #
    def with(scope = nil)
      groups_array(:with, scope)
    end

    # Finds the previously set groups of the given type and scope.
    #
    # @param  [Symbol] group_type
    #         either `:with` or `:without`.
    #
    # @param  [Symbol,Nil] scope
    #         any of `:global`, `:local`, or `nil`; otherwise, an error is
    #         thrown.
    #
    # @return [Array<Symbol>] The previously set groups.
    #
    def groups_array(group_type, scope)
      key = key_for(group_type)
      if scope.nil?
        get_array(group_type)
      elsif scope == :global
        @global_config[key] ? @global_config[key].split(" ").map(&:to_sym) : []
      elsif scope == :local
        @local_config[key] ? @local_config[key].split(" ").map(&:to_sym) : []
      else
        Bundler.ui.error "Invalid scope #{scope} given. Please use :local or :global."
        exit 1
      end
    end

    # @local_config["BUNDLE_PATH"] should be prioritized over ENV["BUNDLE_PATH"]
    # Always returns an absolute path to the bundle directory
    # TODO: Refactor this method
    def path
      # TODO: Shoudl we consider the @current_config here?
      key  = key_for(:path)
      path = ENV[key] || @global_config[key]
      set_path = ""
      install_path = ""

      # We don't use @current_config here, because we no longer accept the path
      # flag.
      if path && !@local_config.key?(key)
        path = "#{path}/#{Bundler.ruby_scope}" if path != Bundler.rubygems.gem_dir
        set_path = path
      end

      if path = self[:path]
        path = "#{path}/#{Bundler.ruby_scope}" if path != Bundler.rubygems.gem_dir
        set_path = path
      else
        set_path = File.join(@root, Bundler.ruby_scope)
      end

      if Pathname.new(set_path).absolute?
        # The user specified an absolute path.
        # The set path is the root bundler (gems.rb) path, the systems gem
        # path, or any other absolute path.
        install_path = set_path
      else
        # The user specified a relative path.
        # The install path is this path expanded from the root bundler
        # (gems.rb) directory.
        install_path = File.join(Bundler.root, set_path)
      end

      install_path
    end

    def allow_sudo?
      !@local_config.key?(key_for(:path))
    end

    def ignore_config?
      ENV["BUNDLE_IGNORE_CONFIG"]
    end

    def app_cache_path
      @app_cache_path ||= begin
        path = self[:cache_path] || "vendor/cache"
        raise InvalidOption, "Cache path must be relative to the bundle path" if path.start_with?("/")
        path
      end
    end

  private

    def key_for(key)
      if key.is_a?(String) && /https?:/ =~ key
        key = normalize_uri(key).to_s
      end
      key = key.to_s.gsub(".", "__").upcase
      "BUNDLE_#{key}"
    end

    def parent_setting_for(name)
      split_specfic_setting_for(name)[0]
    end

    def specfic_gem_for(name)
      split_specfic_setting_for(name)[1]
    end

    def split_specfic_setting_for(name)
      name.split(".")
    end

    def is_bool(name)
      BOOL_KEYS.include?(name.to_s) || BOOL_KEYS.include?(parent_setting_for(name.to_s))
    end

    def to_bool(value)
      !(value.nil? || value == "" || value =~ /^(false|f|no|n|0)$/i || value == false)
    end

    def is_num(value)
      NUMBER_KEYS.include?(value.to_s)
    end

    def get_array(key)
      self[key] ? self[key].split(":").map(&:to_sym) : []
    end

    def set_array(key, array, scope)
      if scope != :current and scope != :local and scope != :global
        Bundler.ui.error "Invalid scope #{scope} given. Please use :local or :global."
        exit 1
      end

      if array
        value = (array.empty? ? nil : array.join(":"))
        if scope == :current
          self[key] = value if array
        elsif scope == :local
          set_local(key, value) if array
        elsif scope == :global
          set_global(key, value) if array
        end
      end
    end

    def set_key(key, value, hash, file)
      key = key_for(key)

      unless hash[key] == value
        hash[key] = value
        hash.delete(key) if value.nil?
        FileUtils.mkdir_p(file.dirname)
        require "bundler/psyched_yaml"
        File.open(file, "w") {|f| f.puts YAML.dump(hash) }
      end

      value
    rescue Errno::EACCES
      raise PermissionError.new(file)
    end

    def global_config_file
      file = ENV["BUNDLE_CONFIG"] || File.join(Bundler.rubygems.user_home, ".bundle/config")
      Pathname.new(file)
    end

    def local_config_file
      Pathname.new(@root).join("config") if @root
    end

    def load_config(config_file)
      valid_file = config_file && config_file.exist? && !config_file.size.zero?
      if !ignore_config? && valid_file
        config_regex = /^(BUNDLE_.+): (['"]?)(.*(?:\n(?!BUNDLE).+)?)\2$/
        raise PermissionError.new(config_file, :read) unless config_file.readable?
        config_pairs = config_file.read.scan(config_regex).map do |m|
          key, _, value = m
          [convert_to_backward_compatible_key(key), value.gsub(/\s+/, " ").tr('"', "'")]
        end
        Hash[config_pairs]
      else
        {}
      end
    end

    def convert_to_backward_compatible_key(key)
      key = "#{key}/" if key =~ /https?:/i && key !~ %r[/\Z]
      key = key.gsub(".", "__") if key.include?(".")
      key
    end

    # TODO: duplicates Rubygems#normalize_uri
    # TODO: is this the correct place to validate mirror URIs?
    def normalize_uri(uri)
      uri = uri.to_s
      uri = "#{uri}/" unless uri =~ %r[/\Z]
      uri = URI(uri)
      unless uri.absolute?
        raise ArgumentError, "Gem sources must be absolute. You provided '#{uri}'."
      end
      uri
    end
  end
end
