# frozen_string_literal: true
module Bundler
  class CLI::Init
    attr_reader :options
    def initialize(options)
      @options = options
    end

    def run
      if File.exist?(gemfile)
        Bundler.ui.error "#{gemfile} already exists at #{SharedHelpers.pwd}/#{gemfile}"
        exit 1
      end

      if options[:gemspec]
        gemspec = File.expand_path(options[:gemspec])
        unless File.exist?(gemspec)
          Bundler.ui.error "Gem specification #{gemspec} doesn't exist"
          exit 1
        end

        spec = Bundler.load_gemspec_uncached(gemspec)

        puts "Writing new Gemfile to #{SharedHelpers.pwd}/#{gemfile}"
        File.open(gemfile, "wb") do |file|
          file << "# Generated from #{gemspec}\n"
          file << spec.to_gemfile
        end
      else
        puts "Writing new #{gemfile} to #{SharedHelpers.pwd}/#{gemfile}"
        FileUtils.cp(File.expand_path("../../templates/#{gemfile}", __FILE__), gemfile)
      end
    end

  private

    def gemfile
      @gemfile ||= Bundler.feature_flag.new_gemfile_name? ? "gems.rb" : "Gemfile"
    end
  end
end
