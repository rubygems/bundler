# encoding: utf-8
require 'spec_helper'
require 'bundler'

describe Bundler do
  describe "#load_gemspec_uncached" do
    subject(:gemspec) { tmp("test.gemspec") }

    context "with incorrect YAML file" do
      before do
        File.open(gemspec, "wb") do |f|
          f.write strip_whitespace(<<-GEMSPEC)
            ---
              {:!00 ao=gu\g1= 7~f
          GEMSPEC
        end
      end

      context "on Ruby 1.8", :ruby => "1.8" do
        it "should catch YAML syntax errors" do
          expect { Bundler.load_gemspec_uncached(gemspec) }.
            to raise_error(Bundler::GemspecError)
        end
      end

      context "on Ruby 1.9", :ruby => "1.9" do
        context "with Syck as YAML::Engine" do
          it "raises a GemspecError after YAML load throws ArgumentError" do
            orig_yamler, YAML::ENGINE.yamler = YAML::ENGINE.yamler, 'syck'

            expect { Bundler.load_gemspec_uncached(gemspec) }.
              to raise_error(Bundler::GemspecError)

            YAML::ENGINE.yamler = orig_yamler
          end
        end

        context "with Psych as YAML::Engine" do
          it "raises a GemspecError after YAML load throws Psych::SyntaxError" do
            orig_yamler, YAML::ENGINE.yamler = YAML::ENGINE.yamler, 'psych'

            expect { Bundler.load_gemspec_uncached(gemspec) }.
              to raise_error(Bundler::GemspecError)

            YAML::ENGINE.yamler = orig_yamler
          end
        end
      end
    end

    context "with correct YAML file" do
      it "can load a gemspec with unicode characters with default ruby encoding" do
        # spec_helper forces the external encoding to UTF-8 but that's not the
        # ruby default.
        encoding = nil

        if defined?(Encoding)
          encoding = Encoding.default_external
          Encoding.default_external = "ASCII"
        end

        File.open(gemspec, "wb") do |file|
          file.puts <<-GEMSPEC.gsub(/^\s+/, '')
            # -*- encoding: utf-8 -*-
            Gem::Specification.new do |gem|
              gem.author = "André the Giant"
            end
          GEMSPEC
        end

        expect(Bundler.load_gemspec_uncached(gemspec).author).
          to eq("André the Giant")

        Encoding.default_external = encoding if defined?(Encoding)
      end
    end

  end
end
