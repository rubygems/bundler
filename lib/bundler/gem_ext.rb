module Gem
  class Installer
    def app_script_text(bin_file_name)
      path = @gem_home
      template = File.read(File.join(File.dirname(__FILE__), "templates", "app_script.erb"))
      erb = ERB.new(template, nil, '-')
      erb.result(binding)
    end
  end

  class Specification
    attribute :source
    attribute :location

    def source=(source)
      unless source.is_a?(Bundler::Source) || source.is_a?(Bundler::DirectorySource)
        source = Bundler::Source.new(:uri => source)
      end
      @source = source
    end

    # Hack to fix github's strange marshal file
    def specification_version
      @specification_version && @specification_version.to_i
    end

    include(Module.new do
      def full_gem_path
        @location ? @location : super
      end
    end)
  end
end
