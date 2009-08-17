module Gem
  class Installer
    def app_script_text(bin_file_name)
      path = @gem_home
      template = File.read(File.join(File.dirname(__FILE__), "templates", "app_script.rb"))
      erb = ERB.new(template)
      erb.result(binding)
    end
  end

  class Specification
    attribute :source

    def source=(source)
      source = Bundler::Source.new(source) unless source.is_a?(Bundler::Source)
      @source = source
    end

    # Hack to fix github's strange marshal file
    def specification_version
      @specification_version && @specification_version.to_i
    end
  end
end
