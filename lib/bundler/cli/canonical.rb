# frozen_string_literal: true

module Bundler
  class CLI::Canonical
    def initialize(options)
      @options = options
    end

    def run
      contents = Gemfile.full_gemfile(:show_summary => true, :as_string => true)

      if @options[:view]
        puts contents
      else
        SharedHelpers.write_to_gemfile(Bundler.default_gemfile, contents)
      end
    end
  end
end
