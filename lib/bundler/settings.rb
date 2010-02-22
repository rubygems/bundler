module Bundler
  class Settings
    def initialize(root)
      @root   = root
      @config = File.exist?(config_file) ? YAML.load_file(config_file) : {}
    end

    def [](key)
      key = "BUNDLE_#{key.to_s.upcase}"
      @config[key] || ENV[key]
    end

    def []=(key, value)
      key = "BUNDLE_#{key.to_s.upcase}"
      @config[key] = value
      FileUtils.mkdir_p(config_file.dirname)
      File.open(config_file, 'w') do |f|
        f.puts @config.to_yaml
      end
      value
    end

    def without=(array)
      self[:without] = array.join(":")
    end

    def without
      self[:without] ? self[:without].split(":").map { |w| w.to_sym } : []
    end

  private

    def config_file
      Pathname.new("#{@root}/.bundle/config")
    end
  end
end