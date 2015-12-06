require "spec_helper"
require "bundler/mirror"

describe Bundler::Settings::Mirror do
  let(:mirror) { Bundler::Settings::Mirror.new }

  it "returns zero when fallback_timeout is not set" do
    expect(mirror.fallback_timeout).to eq(0)
  end

  it "takes a number as a fallback_timeout" do
    mirror.fallback_timeout = 1
    expect(mirror.fallback_timeout).to eq(1)
  end

  it "takes truthy as a default fallback timeout" do
    mirror.fallback_timeout = true
    expect(mirror.fallback_timeout).to eq(0.1)
  end

  it "takes falsey as a zero fallback timeout" do
    mirror.fallback_timeout = false
    expect(mirror.fallback_timeout).to eq(0)
  end

  it "takes a string but returns a uri" do
    mirror.uri = "http://localhost:9292"
    expect(mirror.uri).to eq(URI("http://localhost:9292"))
  end

  it "takes an uri for the uri" do
    mirror.uri = URI("http://localhost:9293")
    expect(mirror.uri).to eq(URI("http://localhost:9293"))
  end
end

describe Bundler::Settings::Mirrors do
  let(:mirrors) { Bundler::Settings::Mirrors.new }

  it "returns an empty mirror for a new uri" do
    mirror = mirrors["http://rubygems.org/"]
    expect(mirror).to eq(Bundler::Settings::Mirror.new)
  end

  it "takes a mirror key and assings the uri" do
    mirrors.parse("mirror.http://rubygems.org/", "http://localhost:9292")
    expect(mirrors["http://rubygems.org/"].uri).to eq(URI("http://localhost:9292"))
  end

  it "takes a mirror fallback_timeout and assigns the timeout" do
    mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "2")
    expect(mirrors["http://rubygems.org/"].fallback_timeout).to eq(2)
  end
end
