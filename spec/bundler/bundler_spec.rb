# encoding: utf-8
require 'spec_helper'
require 'bundler'

describe Bundler do
  describe "#load_gemspec_uncached" do
    it "should catch Psych syntax errors" do
      gemspec = <<-GEMSPEC
{:!00 ao=gu\g1= 7~f
GEMSPEC
      File.open(tmp("test.gemspec"), 'wb') do |file|
        file.puts gemspec
      end

      proc {
        Bundler.load_gemspec_uncached(tmp("test.gemspec"))
      }.should raise_error(Bundler::GemspecError)
    end

    it "can load a gemspec with unicode characters with default ruby encoding" do
      # spec_helper forces the external encoding to UTF-8 but that's not the
      # ruby default.
      encoding = nil

      if defined?(Encoding)
        encoding = Encoding.default_external
        Encoding.default_external = "ASCII"
      end

      File.open(tmp("test.gemspec"), "wb") do |file|
        file.puts <<-G.gsub(/^\s+/, '')
          # -*- encoding: utf-8 -*-
          Gem::Specification.new do |gem|
            gem.author = "André the Giant"
          end
        G
      end

      gemspec = Bundler.load_gemspec_uncached(tmp("test.gemspec"))
      gemspec.author.should == "André the Giant"

      Encoding.default_external = encoding if defined?(Encoding)
    end
  end
end
