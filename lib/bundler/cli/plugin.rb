module Bundler
  class CLI::Plugin
    attr_reader :options
    attr_reader :args
    def initialize(options, args)
      @options = options
      @action = args[0]
      @name = args[1]
    end

    def run
      plugin_manager = Bundler::Plugin::Manager.instance
      plugins = plugin_manager.installed_plugins
      if @action == "install"
        deps = []
        deps << Dependency.new("bundler-#{@name}", [">= 0"], {})
        Bundler.set_plugin_install_mode
        sources = SourceList.new
        plugin_definition = Definition.new(nil, deps, sources, [])
        Installer.install_plugin(plugin_definition)


        if !plugins.include?("bundler-#{@name}")
          plugin_manager.install_plugin("bundler-#{@name}")
          plugin_definition.specs.to_a.each do |spec|
            next if spec.name == 'bundler'
            begin
              require spec.name
              Bundler.ui.confirm "Bundler plugin '#{@name}' has been successfully installed"
            rescue LoadError
              raise "Bundler plugin '#{@name}' couldn't be installed"
            end
          end
        else
          plugin_definition.specs.to_a.each do |spec|
            next if spec.name == 'bundler'
            begin
              require spec.name
              Bundler.ui.info "Bundler plugin '#{@name}' is already installed"
            rescue LoadError
              raise "Bundler plugin '#{@name}' is installed but can't be found in the system"
            end
          end
        end
      elsif @action == "uninstall"
        if plugins.include?("bundler-#{@name}")
          plugin_manager.uninstall_plugin("bundler-#{@name}")
          Bundler.ui.confirm "Bundler plugin '#{@name}' has been successfully uninstalled"
        else
          Bundler.ui.error "Bundler plugin '#{@name}' doesn't exist"
        end
      end
    end

  end
end
