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

      expect(proc {
        Bundler.load_gemspec_uncached(tmp("test.gemspec"))
      }).to raise_error(Bundler::GemspecError)
    end
  end
end
