module Bundler
  class CLI::Clean
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      reqire_path_or_force
      Bundler.load.clean(options[:"dry-run"])
    end

  protected

    def reqire_path_or_force
      if !Bundler.settings[:path] && !options[:force]
        Bundler.ui.error "Cleaning all the gems on your system is dangerous! " \
          "To remove every gem not in this bundle, run `bundle clean --force`."
        exit 1
      end
    end

  end
end
