require 'spec_helper'

describe "bundle retry" do
  it "return successful result if no errors" do
    attempts = 0
    result = Bundler::Retry.new(nil, 3).attempt do
      attempts += 1
      :success
    end
    expect(result).to eq(:success)
    expect(attempts).to eq(1)
  end

  it "returns the first valid result" do
    jobs = [->{ raise "foo" }, ->{ :bar }, ->{ raise "foo" }]
    attempts = 0
    result = Bundler::Retry.new(nil, 3).attempt do
      attempts += 1
      job = jobs.shift
      job.call
    end
    expect(result).to eq(:bar)
    expect(attempts).to eq(2)
  end

  it "raises the last error" do
    error    = Bundler::GemfileNotFound
    attempts = 0
    expect {
      Bundler::Retry.new(nil, 3).attempt do
        attempts += 1
        raise error
      end
    }.to raise_error(error)
    expect(attempts).to eq(4)
  end
end
