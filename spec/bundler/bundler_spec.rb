# encoding: utf-8
require "spec_helper"
require "bundler"

describe Bundler do
  describe "#ruby_version" do
    subject { Bundler.ruby_version }

    let(:bundler_ruby_version) { subject }

    before do
      Bundler.instance_variable_set("@ruby_version", nil)
    end

    it "should return an instance of Bundler::RubyVersion" do
      expect(subject).to be_kind_of(Bundler::RubyVersion)
    end

    it "memoizes the instance of Bundler::RubyVersion" do
      expect(Bundler::RubyVersion).to receive(:new).once.and_call_original
      2.times { Bundler.ruby_version }
    end

    describe "#version" do
      it "should return a copy of the value of RUBY_VERSION" do
        expect(subject.version).to eq(RUBY_VERSION)
        expect(subject.version).to_not be(RUBY_VERSION)
      end
    end

    describe "#engine" do
      context "RUBY_ENGINE is defined" do
        before { stub_const("RUBY_ENGINE", "jruby") }
        before { stub_const("JRUBY_VERSION", "2.1.1") }

        it "should return a copy of the value of RUBY_ENGINE" do
          expect(subject.engine).to eq("jruby")
          expect(subject.engine).to_not be(RUBY_ENGINE)
        end
      end

      context "RUBY_ENGINE is not defined" do
        before { stub_const("RUBY_ENGINE", nil) }

        it "should return the string 'ruby'" do
          expect(subject.engine).to eq("ruby")
        end
      end
    end

    describe "#engine_version" do
      context "engine is ruby" do
        before do
          stub_const("RUBY_VERSION", "2.2.4")
          allow(Bundler).to receive(:ruby_engine).and_return("ruby")
        end

        it "should return a copy of the value of RUBY_VERSION" do
          expect(bundler_ruby_version.engine_version).to eq("2.2.4")
          expect(bundler_ruby_version.engine_version).to_not be(RUBY_VERSION)
        end
      end

      context "engine is rbx" do
        before do
          stub_const("RUBY_ENGINE", "rbx")
          stub_const("Rubinius::VERSION", "2.0.0")
        end

        it "should return a copy of the value of Rubinius::VERSION" do
          expect(bundler_ruby_version.engine_version).to eq("2.0.0")
          expect(bundler_ruby_version.engine_version).to_not be(Rubinius::VERSION)
        end
      end

      context "engine is jruby" do
        before do
          stub_const("RUBY_ENGINE", "jruby")
          stub_const("JRUBY_VERSION", "2.1.1")
        end

        it "should return a copy of the value of JRUBY_VERSION" do
          expect(bundler_ruby_version.engine_version).to eq("2.1.1")
          expect(bundler_ruby_version.engine_version).to_not be(JRUBY_VERSION)
        end
      end

      context "engine is some other ruby engine" do
        before do
          stub_const("RUBY_ENGINE", "not_supported_ruby_engine")
          allow(Bundler).to receive(:ruby_engine).and_return("not_supported_ruby_engine")
        end

        it "should raise a BundlerError with a 'not recognized' message" do
          expect { bundler_ruby_version.engine_version }.to raise_error(Bundler::BundlerError, "RUBY_ENGINE value not_supported_ruby_engine is not recognized")
        end
      end
    end

    describe "#patchlevel" do
      it "should return a string with the value of RUBY_PATCHLEVEL" do
        expect(subject.patchlevel).to eq(RUBY_PATCHLEVEL.to_s)
      end
    end
  end

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
  end
end
