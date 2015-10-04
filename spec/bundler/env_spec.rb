require "spec_helper"
require "bundler/settings"

describe Bundler::Env do
  let(:env) { described_class.new }

  describe "#report" do
    context "when Gemfile contains a gemspec and print_gemspecs is true" do
      let(:gemspec) do
        <<-GEMSPEC.gsub(/^\s+/, "")
          Gem::Specification.new do |gem|
            gem.name = "foo"
            gem.author = "Fumofu"
          end
        GEMSPEC
      end

      before do
        gemfile("gemspec")

        File.open(bundled_app.join("foo.gemspec"), "wb") do |f|
          f.write(gemspec)
        end
      end

      it "prints the contents of that gemspec" do
        output = env.report(:print_gemspecs => true)
        expect(output.gsub(/^\s+/, "")).to include(gemspec)
      end
    end
  end
end
