module Bubble
  class Environment
    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    def setup
      # Has to happen first
      cripple_rubygems

      # Activate the specs
      specs.each do |spec|
        Gem.loaded_specs[spec.name] = spec
      end
      $LOAD_PATH.unshift *load_paths
      self
    end

    def dependencies
      @definition.dependencies
    end

    def lock
      FileUtils.mkdir_p("#{root}/vendor")
      write_yml_lock
      write_rb_lock
    end

    def specs
      @specs ||= Resolver.resolve(@definition.actual_dependencies, index)
    end

    def index
      @index ||= begin
        index = Index.new
        sources.reverse_each do |source|
          index.merge! source.local_specs
        end
        index
      end
    end

  private

    def sources
      @definition.sources
    end

    def load_paths
      specs.map { |s| s.load_paths }.flatten
    end

    def cripple_rubygems
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        me = File.expand_path("../../", __FILE__)
        $LOAD_PATH.reject! do |p|
          p != File.dirname(__FILE__) &&
            Gem.path.any? { |gp| p.include?(gp) }
        end
        $LOAD_PATH.unshift me
        $LOAD_PATH.uniq!
      end

      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias require gem_original_require
        end

        def gem(*)
          # Silently ignore calls to gem
        end
      end
    end

    def write_rb_lock
      template = File.read(File.expand_path("../templates/environment.erb", __FILE__))
      erb = ERB.new(template, nil, '-')
      File.open("#{root}/vendor/environment.rb", 'w') do |f|
        f.puts erb.result(binding)
      end
    end

    def write_yml_lock
      yml = details.to_yaml
      File.open("#{root}/vendor/lock.yml", 'w') do |f|
        f.puts yml
      end
    end

    def details
      details = {}
      details["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }
      details["specs"] = specs.map { |s| {s.name => s.version.to_s} }
      details["dependencies"] = dependencies.map { |d| {d.name => d.version_requirements.to_s} }
      details
    end

  end
end