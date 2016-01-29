# encoding: utf-8
require "spec_helper"
require "bundler"

describe Bundler do
  describe "#load_gemspec_uncached" do
    let(:app_gemspec_path) { tmp("test.gemspec") }
    subject { Bundler.load_gemspec_uncached(app_gemspec_path) }

    context "with incorrect YAML file" do
      before do
        File.open(app_gemspec_path, "wb") do |f|
          f.write strip_whitespace(<<-GEMSPEC)
            ---
              {:!00 ao=gu\g1= 7~f
          GEMSPEC
        end
      end

      it "catches YAML syntax errors" do
        expect { subject }.to raise_error(Bundler::GemspecError)
      end

      context "on Rubies with a settable YAML engine", :if => defined?(YAML::ENGINE) do
        context "with Syck as YAML::Engine" do
          it "raises a GemspecError after YAML load throws ArgumentError" do
            orig_yamler = YAML::ENGINE.yamler
            YAML::ENGINE.yamler = "syck"

            expect { subject }.to raise_error(Bundler::GemspecError)

            YAML::ENGINE.yamler = orig_yamler
          end
        end

        context "with Psych as YAML::Engine" do
          it "raises a GemspecError after YAML load throws Psych::SyntaxError" do
            orig_yamler = YAML::ENGINE.yamler
            YAML::ENGINE.yamler = "psych"

            expect { subject }.to raise_error(Bundler::GemspecError)

            YAML::ENGINE.yamler = orig_yamler
          end
        end
      end
    end

    context "with correct YAML file", :if => defined?(Encoding) do
      it "can load a gemspec with unicode characters with default ruby encoding" do
        # spec_helper forces the external encoding to UTF-8 but that's not the
        # default until Ruby 2.0
        verbose = $VERBOSE
        $VERBOSE = false
        encoding = Encoding.default_external
        Encoding.default_external = "ASCII"
        $VERBOSE = verbose

        File.open(app_gemspec_path, "wb") do |file|
          file.puts <<-GEMSPEC.gsub(/^\s+/, "")
            # -*- encoding: utf-8 -*-
            Gem::Specification.new do |gem|
              gem.author = "André the Giant"
            end
          GEMSPEC
        end

        expect(subject.author).to eq("André the Giant")

        verbose = $VERBOSE
        $VERBOSE = false
        Encoding.default_external = encoding
        $VERBOSE = verbose
      end
    end

    context "validate is true" do
      subject { Bundler.load_gemspec_uncached(app_gemspec_path, true) }

      context "and there are gemspec validation errors" do
        let(:ui_shell) { double(:ui_shell) }

        before do
          allow(Bundler::UI::Shell).to receive(:new).and_return(ui_shell)
          allow(Bundler.rubygems).to receive(:validate) {
            raise Gem::InvalidSpecificationException.new("TODO is not an author")
          }
        end

        it "should raise a Gem::InvalidSpecificationException and produce a helpful warning message" do
          File.open(app_gemspec_path, "wb") do |file|
            file.puts <<-GEMSPEC.gsub(/^\s+/, "")
              Gem::Specification.new do |gem|
                gem.author = "TODO"
              end
            GEMSPEC
          end

          expect { subject }.to raise_error(Gem::InvalidSpecificationException,
            "The gemspec at #{app_gemspec_path} is not valid. "\
            "Please fix this gemspec.\nThe validation error was 'TODO is not an author'\n")
        end
      end
    end
  end
end
