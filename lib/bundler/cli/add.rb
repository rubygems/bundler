# frozen_string_literal: true
require "net/http"
require "yaml"

module Bundler
  class CLI::Add
    def initialize(name, version)
      @name = name
      @version = version || last_version_number
    end

    def run
      Bundler.default_gemfile.open("a") do |f|
        f.puts
        f.puts output_line
      end
      Bundler.ui.confirm "Added to Gemfile: #{output_line}"
    end

  private

    def last_version_number
      uri = URI.parse("https://rubygems.org/api/v1/gems/#{@name}.yaml")
      response = Net::HTTP.get(uri)
      YAML.load(response)["version"]
    end

    def output_line
      %(|gem "#{@name}", "#{approximate_recommendation}"|)
    end

    def approximate_recommendation
      Gem::Version.new(@version).approximate_recommendation
    end
  end
end
