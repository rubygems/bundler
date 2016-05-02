# frozen_string_literal: true
module Bundler
  class CLI::Init
    attr_reader :options
    def initialize(options)
      @options = options
    end

    def run
      %w(gems.rb Gemfile).each do |f|
        if File.exist?(f)
          Bundler.ui.error "#{f} already exists at #{SharedHelpers.pwd}/#{f}"
          exit 1
        end
      end

      if options[:gemspec]
        gemspec = File.expand_path(options[:gemspec])
        unless File.exist?(gemspec)
          Bundler.ui.error "Gem specification #{gemspec} doesn't exist"
          exit 1
        end
        spec = Gem::Specification.load(gemspec)
        puts "Writing new gems.rb to #{SharedHelpers.pwd}/gems.rb"

        File.open("gems.rb", "wb") do |file|
          file << "# Generated from #{gemspec}\n"
          file << spec.to_gemfile
        end
      else
        puts "Writing new gems.rb to #{SharedHelpers.pwd}/gems.rb"
        FileUtils.cp(File.expand_path("../../templates/gems.rb", __FILE__), "gems.rb")
      end
    end
  end
end
