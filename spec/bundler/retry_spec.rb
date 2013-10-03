require 'spec_helper'

describe "bundle retry" do
  it "return successful result if no errors" do
    attempts = 0
    result = Bundler::Retry.new(nil, nil, 3).attempt do
      attempts += 1
      :success
    end
    expect(result).to eq(:success)
    expect(attempts).to eq(1)
  end

  it "defaults to retrying twice" do
    attempts = 0
    expect {
      Bundler::Retry.new(nil).attempt do
        attempts += 1
        raise "nope"
      end
    }.to raise_error
    expect(attempts).to eq(3)
  end

  it "returns the first valid result" do
    jobs = [Proc.new{ raise "foo" }, Proc.new{ :bar }, Proc.new{ raise "foo" }]
    attempts = 0
    result = Bundler::Retry.new(nil, nil, 3).attempt do
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
      Bundler::Retry.new(nil, nil, 3).attempt do
        attempts += 1
        raise error
      end
    }.to raise_error(error)
    expect(attempts).to eq(4)
  end

  it "raises exceptions" do
    error = Bundler::GemfileNotFound
    attempts = 0
    expect {
      Bundler::Retry.new(nil, error).attempt do
        attempts += 1
        raise error
      end
    }.to raise_error(error)
    expect(attempts).to eq(1)
  end
end
