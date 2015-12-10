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
  context "with a default mirrors" do
    let(:mirrors) { Bundler::Settings::Mirrors.new }

    it "returns an empty mirror for a new uri" do
      mirror = mirrors.for("http://rubygems.org/")
      expect(mirror).to eq(Bundler::Settings::Mirror.new("http://rubygems.org/"))
    end

    it "takes a mirror key and assings the uri" do
      mirrors.parse("mirror.http://rubygems.org/", "http://localhost:9292")
      expect(mirrors.for("http://rubygems.org/").uri).to eq(URI("http://localhost:9292"))
    end

    it "takes a mirror fallback_timeout and assigns the timeout" do
      mirrors.parse("mirror.http://rubygems.org/", "http://localhost:9292")
      mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "2")
      expect(mirrors.for("http://rubygems.org/").fallback_timeout).to eq(2)
    end
  end

  context "with a stubbed with a successfull probe mirrors and a fallback timeout" do
    let(:mirrors) do
      probe = double()
      allow(probe).to receive(:probe_availability).and_return(true)
      Bundler::Settings::Mirrors.new(probe)
    end

    context "with a default fallback_timeout defined" do
      before do
        mirrors.parse("mirror.http://rubygems.org/", "http://localhost:9292")
        mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "true")
      end

      it "returns the mirrored uri" do
        expect(mirrors.for("http://rubygems.org").uri).to eq(URI("http://localhost:9292"))
      end
    end

    context "setup to fallback all uris" do
      let(:localhost_uri) { URI("http://localhost:9292") }

      before do
        mirrors.parse("mirror.all", localhost_uri)
      end

      it "returns the same mirror for any uri" do
        expect(mirrors.for("http://bla/").uri).to eq(localhost_uri)
        expect(mirrors.for("http://1.com/").uri).to eq(localhost_uri)
        expect(mirrors.for("http://any.org").uri).to eq(localhost_uri)
      end

      it "returns the mirrored uri for rubygems" do
        expect(mirrors.for("http://rubygems.org").uri).to eq(localhost_uri)
      end
      it "returns the mirrored uri for any other url" do
        expect(mirrors.for("http://whatever.com/").uri).to eq(localhost_uri)
      end
    end
  end

  context "with a stubbed with an unsuccessfull probe mirrors and a fallback timeout" do
    let(:localhost_uri) { URI("http://localhost:9292") }
    let(:mirrors) do
      probe = double()
      allow(probe).to receive(:probe_availability).and_return(false)
      Bundler::Settings::Mirrors.new(probe)
    end

    context "mirroring all the urls with a fallback timeout" do
      before do
        mirrors.parse("mirror.all", localhost_uri)
        mirrors.parse("mirror.all.fallback_timeout", true)
      end

      context "with a default fallback_timeout defined" do
        it "returns the original uri" do
          expect(mirrors.for("http://whatever.com").uri).to eq(URI("http://whatever.com/"))
        end
      end
    end

    context "mirroring one url with a default fallback timeout" do
      before do
        mirrors.parse("mirror.http://rubygems.org/", "http://localhost:9292")
        mirrors.parse("mirror.http://rubygems.org/.fallback_timeout", "true")
      end

      it "returns the original uri for a different uri" do
        expect(mirrors.for("http://whatever.com").uri).to eq(URI("http://whatever.com/"))
      end
      it "returns the original uri for the mirrored uri" do
        expect(mirrors.for("http://rubygems.org/").uri).to eq(URI("http://rubygems.org/"))
      end
    end
  end
end
