require "spec_helper"
require "bundler"
require "bundler/friendly_errors"

describe Bundler, "friendly errors" do
  it "rescues ArgumentErrors" do
    expect {
      Bundler.with_friendly_errors do
        raise ArgumentError.new("Ambiguous task")
      end
    }.to_not raise_error
  end
end
