module Gem
  class Installer
    def app_script_text(bin_file_name)
      return unless Bundler::CLI.default_path
      path = Pathname.new(Bundler::CLI.default_path).expand_path
      <<-TEXT
#{shebang bin_file_name}
require "#{path.join("environments", "default")}"
load "#{path.join("gems", @spec.full_name, @spec.bindir, bin_file_name)}"
      TEXT
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
