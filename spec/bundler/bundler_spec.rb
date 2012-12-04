require 'spec_helper'
require 'bundler'

describe Bundler do
  describe "#load_gemspec_uncached" do

    before do
      @gemspec = tmp("test.gemspec")
      @gemspec.open('wb') do |f|
        f.write strip_whitespace(<<-GEMSPEC)
          ---
            {:!00 ao=gu\g1= 7~f
        GEMSPEC
      end
    end

    describe "on Ruby 1.8", :ruby => "1.8" do
      it "should catch YAML syntax errors" do
        expect { Bundler.load_gemspec_uncached(@gemspec) }.
          to raise_error(Bundler::GemspecError)
      end
    end

    context "on Ruby 1.9", :ruby => "1.9" do
      context "with Syck as YAML::Engine" do
        it "raises a GemspecError after YAML load throws ArgumentError" do
          orig_yamler, YAML::ENGINE.yamler = YAML::ENGINE.yamler, 'syck'

          expect { Bundler.load_gemspec_uncached(@gemspec) }.
            to raise_error(Bundler::GemspecError)

          YAML::ENGINE.yamler = orig_yamler
        end
      end

      context "with Psych as YAML::Engine" do
        it "raises a GemspecError after YAML load throws Psych::SyntaxError" do
          orig_yamler, YAML::ENGINE.yamler = YAML::ENGINE.yamler, 'psych'

          expect { Bundler.load_gemspec_uncached(@gemspec) }.
            to raise_error(Bundler::GemspecError)

          YAML::ENGINE.yamler = orig_yamler
        end
      end
    end

  end
end
