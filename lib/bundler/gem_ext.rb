module Gem
  class Installer
    def app_script_text(bin_file_name)
      return unless Bundler::CLI.default_path
      path = Pathname.new(Bundler::CLI.default_path).expand_path
      template = File.read(File.join(File.dirname(__FILE__), "templates", "app_script.rb"))
      erb = ERB.new(template)
      erb.result(binding)
    end
  end

  class Specification
    attribute :source

    def source=(source)
      @source = source.is_a?(URI) ? source : URI.parse(source)
      raise ArgumentError, "The source must be an absolute URI" unless @source.absolute?
    end
  end
end
