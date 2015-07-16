require 'uri'

module Bundler
  class Settings
    BOOL_KEYS = %w(frozen cache_all no_prune disable_local_branch_check ignore_messages ignore_warnings gem.mit gem.coc).freeze
    NUMBER_KEYS = %w(retry timeout redirect).freeze
    DEFAULT_CONFIG = {:retry => 3, :timeout => 10, :redirect => 5}

    def initialize(root = nil)
      @root          = root
      @current_config = {}
      @local_config  = load_config(local_config_file)
      @global_config = load_config(global_config_file)
    end

    def [](name)
      key = key_for(name)
      value = (@current_config[key] || @local_config[key] || ENV[key] || @global_config[key] || DEFAULT_CONFIG[name])

      case
      when !value.nil? && is_bool(name)
        to_bool(value)
      when !value.nil? && is_num(name)
        value.to_i
      else
        value
      end
    end

    # In Bundler pre 2.0 any command ever set was stored in the local config
    # file. In Bundler 2.0 they are only saved for that current command and
    # `bundle config <setting name> <setting value>` is used for setting
    # remembered arguments.
    # See https://trello.com/c/yGsPNDpg
    def []=(key, value)
      @use_current ||= (Bundler::VERSION.split(".")[0].to_i >= 2)
      if @use_current
        set_current(key, value)
      else
        set_local(key, value)
      end
    end

    def set_config(key, value, options = {})
      config = options.fetch(:config, :current)
      case config
      when :current
        set_current(key, value)
      when :global
        set_global(key, value)
      when :local
        set_local(key, value)
      end
    end

    def set_current(key, value)
      key = key_for key
      @current_config[key] = value
    end

    def set_local(key, value)
      local_config_file or raise GemfileNotFound, "Could not locate Gemfile"
      set_key(key, value, @local_config, local_config_file)
    end

    def delete(key)
      @local_config.delete(key_for(key))
    end

    def set_global(key, value)
      set_key(key, value, @global_config, global_config_file)
    end

    def all
      env_keys = ENV.keys.select { |k| k =~ /BUNDLE_.*/ }

      keys = @current_config.keys | @global_config.keys | @local_config.keys | env_keys | DEFAULT_CONFIG.keys

      keys.map do |key|
        key.to_s.sub(/^BUNDLE_/, '').gsub(/__/, ".").downcase
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
      locations[:local]  = @local_config[key] if @local_config.key?(key)
      locations[:env]    = ENV[key] if ENV[key]
      locations[:global] = @global_config[key] if @global_config.key?(key)
      locations[:default] = DEFAULT_CONFIG[key] if DEFAULT_CONFIG.key?(key)
      locations
    end

    def pretty_values_for(exposed_key)
      key = key_for(exposed_key)

      locations = []
      if @current_config.key?(key)
        locations << message_for_config(:current) + " #{key}: #{@current_config[key]}"
      end

      if @local_config.key?(key)
        locations << message_for_config(:local) + " #{key}: #{@local_config[key].inspect}"
      end

      if value = ENV[key]
        locations << message_for_config(:env) + " #{key}: #{value.inspect}"
      end

      if @global_config.key?(key)
        locations << message_for_config(:global) + " #{key}: #{@global_config[key].inspect}"
      end

      if DEFAULT_CONFIG.key?(exposed_key)
        locations << message_for_config(:default) + " #{key}: #{DEFAULT_CONFIG[key].inspect}"
      end

      return ["You have not configured a value for `#{exposed_key}`"] if locations.empty?
      locations
    end

    def message_for_config(config)
      messages = {
        :current => "Set only for this command using command line arguments",
        :local => "Set for your local app (#{local_config_file})",
        :env => "Set via environment",
        :global => "Set for the current user (#{global_config_file})",
        :default => "Set by default"
      }
      messages[config]
    end

    def without=(array)
      set_without(array)
    end

    def with=(array)
      set_with(array)
    end

    def set_with(array, options = {})
      enum = array.to_set
      opposite_group = to_set( config_for_symbol( options.fetch :config, :current )[without_key] )
      resolve_conflicts(enum, opposite_group)
      break_with_without_cache!
      set_array(:with, enum, options)
    end

    def set_without(array, options = {})
      enum = array.to_set
      opposite_group = to_set( config_for_symbol( options.fetch :config, :current )[with_key] )
      resolve_conflicts(enum, opposite_group)
      break_with_without_cache!
      set_array(:without, enum, options)
    end

    def without
      get_with_and_without[1].to_a
    end

    def with
      get_with_and_without[0].to_a
    end

    def groups_conflict?(group_one, group_two)
      group_one.to_set.intersect? group_two.to_set
    end

    # @local_config["BUNDLE_PATH"] should be prioritized over ENV["BUNDLE_PATH"]
    def path
      key  = key_for(:path)
      path = ENV[key] || @global_config[key]

      if path && !@local_config.key?(key)
        path = "#{path}/#{Bundler.ruby_scope}" if path != Bundler.rubygems.gem_dir
        return path
      end

      if path = self[:path]
        path = "#{path}/#{Bundler.ruby_scope}" if path != Bundler.rubygems.gem_dir
        File.expand_path(path)
      else
        File.join(@root, Bundler.ruby_scope)
      end
    end

    def allow_sudo?
      !@local_config.key?(key_for(:path))
    end

    def ignore_config?
      ENV['BUNDLE_IGNORE_CONFIG']
    end

    def app_cache_path
      @app_cache_path ||= begin
        path = self[:cache_path] || "vendor/cache"
        raise InvalidOption, "Cache path must be relative to the bundle path" if path.start_with?("/")
        path
      end
    end

    def break_with_without_cache!
      @with_and_without = nil
    end

  private
    def config_for_symbol(sym)
      case sym.to_sym
      when :local
        return @local_config
      when :current
        return @current_config
      when :global
        return @global_config
      when :env
        return ENV
      when :default
        return DEFAULT_CONFIG
      end
    end

    def all_configs
      [@current_config, @local_config, ENV, @global_config, DEFAULT_CONFIG]
    end

    def with_key
      @with_key ||= key_for(:with)
    end

    def without_key
      @without_key ||= key_for(:without)
    end

    def get_with_and_without
      @with_and_without ||= resolve_with_without_groups
    end

    def resolve_with_without_groups
      reverse_config = all_configs.reverse
      with, without = reverse_config.map.with_index do |c, i|
        superior_configs = reverse_config.slice((i+1)..-1)
        override_from_superior_configs c, superior_configs
      end.transpose
      [with.to_set.flatten, without.to_set.flatten]
    end

    def override_from_superior_configs(config, superiors)
      all_values_for_key = proc {|key| superiors.flat_map { |c| to_array(c[key]) } }
      vetted_with = to_set(config[with_key]) - all_values_for_key[without_key]
      vetted_without = to_set(config[without_key]) - all_values_for_key[with_key]
      [vetted_with, vetted_without]
    end

    def resolve_all_conflicts
      cgs = conflicting_groups
      raise ArgumentError, conflicting_groups_message(cgs) unless cgs.empty?
    end

    def resolve_conflicts(array1, array2)
      array1, array2 = to_array(array1), to_array(array2)
      raise ArgumentError, conflicting_groups_message if groups_conflict? array1, array2
    end

    def conflicting_groups_message(cgs = [])
      msg = "With and without groups cannot conflict."
      cgs.each do |k, (w, wo)|
        msg += "\n#{key}: #{message_for_config(k)}"
        msg += "\n\twithout: #{wo.join(',')}"
        msg += "\n\twith: #{w.join(',')}"
      end
      msg
    end

    def conflicting_groups
      with_locations, without_locations = locations(:with), locations(:without)
      (with_locations.keys & without_locations.keys).map do |key|
        groups = [to_set(with_locations[key]), to_set(without_locations[key])]
        groups_conflict?(*groups) ? [key, groups] : nil
      end.compact.to_h
    end

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
      !(value.nil? || value == '' || value =~ /^(false|f|no|n|0)$/i || value == false)
    end

    def is_num(value)
      NUMBER_KEYS.include?(value.to_s)
    end

    def get_array(key)
      array = to_array(self[key])
      array && !array.empty? ? array : []
    end

    def set_array(key, array, options = {})
      array = array.to_a
      value = (array && !array.empty?) ? array.join(":") : nil
      set_config(key, value, options)
    end

    def to_array(string_or_enum)
      return [] if string_or_enum.nil?
      return string_or_enum unless string_or_enum.respond_to? :split
      string_or_enum.split(":").map { |w| w.to_sym }
    end

    def to_set(string_or_enum)
      to_array(string_or_enum).to_set
    end

    def set_key(key, value, hash, file)
      key = key_for(key)

      unless hash[key] == value
        hash[key] = value
        hash.delete(key) if value.nil?
        FileUtils.mkdir_p(file.dirname)
        require 'bundler/psyched_yaml'
        File.open(file, "w") { |f| f.puts YAML.dump(hash) }
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
