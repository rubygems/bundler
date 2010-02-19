module Gem
  class Installer
    remove_method(:app_script_text) if method_defined?(:app_script_text)

    def app_script_text(bin_file_name)
      path = @gem_home
      template = File.read(File.join(File.dirname(__FILE__), "templates", "app_script.erb"))
      erb = ERB.new(template, nil, '-')
      erb.result(binding)
    end
  end

  class Specification
    attr_accessor :source, :location, :no_bundle

    alias no_bundle? no_bundle

    remove_method(:specification_version) if method_defined?(:specification_version)

    # Hack to fix github's strange marshal file
    def specification_version
      @specification_version && @specification_version.to_i
    end

    alias full_gem_path_without_location full_gem_path
    def full_gem_path
      if defined?(@location) && @location
        @location
      else
        full_gem_path_without_location
      end
    end
  end
end
