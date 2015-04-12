require "spec_helper"
require "bundler"
require "bundler/friendly_errors"

describe Bundler, "friendly errors" do
  it "rescues Thor::AmbiguousTaskError and raises SystemExit" do
    expect {
      Bundler.with_friendly_errors do
        raise Thor::AmbiguousTaskError.new("")
      end
    }.to raise_error(SystemExit)
  end

  describe "#issues_url" do
    it "generates a search URL for the exception message" do
      exception = Exception.new("Exception message")

      expect(Bundler.issues_url(exception)).to eq("https://github.com/bundler/bundler/search?q=Exception+message&type=Issues")
    end

    it "generates a search URL for only the first line of a multi-line exception message" do
      exception = Exception.new(<<END)
First line of the exception message
Second line of the exception message
END

      expect(Bundler.issues_url(exception)).to eq("https://github.com/bundler/bundler/search?q=First+line+of+the+exception+message&type=Issues")
    end
  end
end
