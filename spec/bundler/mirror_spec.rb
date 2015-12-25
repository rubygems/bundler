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

  it "takes a string with 'true' as a default fallback timeout" do
    mirror.fallback_timeout = "true"
    expect(mirror.fallback_timeout).to eq(0.1)
  end

  it "takes a string with 'false' as a zero fallback timeout" do
    mirror.fallback_timeout = "false"
    expect(mirror.fallback_timeout).to eq(0)
  end

  it "takes a string for the uri but returns an uri object" do
    mirror.uri = "http://localhost:9292"
    expect(mirror.uri).to eq(URI("http://localhost:9292"))
  end

  it "takes an uri object for the uri" do
    mirror.uri = URI("http://localhost:9293")
    expect(mirror.uri).to eq(URI("http://localhost:9293"))
  end

  context "without a uri" do
    it "invalidates the mirror" do
      mirror.validate!
      expect(mirror.valid?).to be_falsey
    end
  end

  context "with an uri" do
    before { mirror.uri = "http://localhost:9292" }

    context "without a fallback timeout" do
      it "should not be valid by default" do
        expect(mirror.valid?).to be_falsey
      end

      context "when probed" do
        let(:probe) { double() }

        context "with a replying mirror" do
          before do
            allow(probe).to receive(:replies?).and_return(true)
            mirror.validate!(probe)
          end

          it "is valid" do
            expect(mirror.valid?).to be_truthy
          end
        end

        context "with a non replying mirror" do
          before do
            allow(probe).to receive(:replies?).and_return(false)
            mirror.validate!(probe)
          end

          it "is still valid" do
            expect(mirror.valid?).to be_truthy
          end
        end
      end
    end

    context "with a fallback timeout" do
      before { mirror.fallback_timeout = 1 }

      it "should not be valid by default" do
        expect(mirror.valid?).to be_falsey
      end

      context "when probed" do
        let(:probe) { double() }

        context "with a replying mirror" do
          before do
            allow(probe).to receive(:replies?).and_return(true)
            mirror.validate!(probe)
          end

          it "is valid" do
            expect(mirror.valid?).to be_truthy
          end

          it "is validated only once" do
            allow(probe).to receive(:replies?).and_raise("Only once!")
            mirror.validate!(probe)
            expect(mirror.valid?).to be_truthy
          end
        end

        context "with a non replying mirror" do
          before do
            allow(probe).to receive(:replies?).and_return(false)
            mirror.validate!(probe)
          end

          it "is not valid" do
            expect(mirror.valid?).to be_falsey
          end

          it "is validated only once" do
            allow(probe).to receive(:replies?).and_raise("Only once!")
            mirror.validate!(probe)
            expect(mirror.valid?).to be_falsey
          end
        end
      end
    end
  end
end

describe Bundler::Settings::Mirrors do
  let(:localhost_uri) { URI("http://localhost:9292") }

  context "with a default mirrors" do
    let(:mirrors) { Bundler::Settings::Mirrors.new }

    it "returns an empty mirror for a new uri" do
      mirror = mirrors.for("http://rubygems.org/")
      expect(mirror).to eq(Bundler::Settings::Mirror.new("http://rubygems.org/"))
    end

    it "parses a mirror key and assings the uri" do
      mirrors.parse("mirror.http://rubygems.org/", localhost_uri)
      expect(mirrors.for("http://rubygems.org/").uri).to eq(localhost_uri)
    end

    context "with a uri parsed already" do
      before { mirrors.parse("mirror.http://rubygems.org/", localhost_uri) }

      it "takes a mirror fallback_timeout and assigns the timeout" do
        mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "2")
        expect(mirrors.for("http://rubygems.org/").fallback_timeout).to eq(2)
      end

      it "parses a 'true' fallback timeout and sets the default timeout" do
        mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "true")
        expect(mirrors.for("http://rubygems.org/").fallback_timeout).to eq(0.1)
      end

      it "parses a 'false' fallback timeout and sets the default timeout" do
        mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "false")
        expect(mirrors.for("http://rubygems.org/").fallback_timeout).to eq(0)
      end
    end
  end

  context "when successfully probed" do
    let(:mirrors) do
      probe = double()
      allow(probe).to receive(:replies?).and_return(true)
      Bundler::Settings::Mirrors.new(probe)
    end

    context "with a default fallback_timeout defined" do
      before do
        mirrors.parse("mirror.http://rubygems.org/", localhost_uri)
        mirrors.parse("mirror.http://rubygems.org.fallback_timeout", "true")
      end

      it "returns the mirrored uri" do
        expect(mirrors.for("http://rubygems.org").uri).to eq(localhost_uri)
      end
    end

    context "with a local mirror for all uris" do
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

  context "with an mirror that does not reply on time" do
    let(:mirrors) do
      probe = double()
      allow(probe).to receive(:replies?).and_return(false)
      Bundler::Settings::Mirrors.new(probe)
    end

    context "with a mirror for all" do
      before { mirrors.parse("mirror.all", localhost_uri) }

      it "returns the mirror uri" do
        expect(mirrors.for("http://whatever.com").uri).to eq(localhost_uri)
      end

      context "with a fallback timeout" do
        before { mirrors.parse("mirror.all.fallback_timeout", "true") }

        it "returns the source uri not the mirror" do
          expect(mirrors.for("http://whatever.com").uri).to eq(URI("http://whatever.com/"))
        end
      end
    end

    context "with a mirror for one url" do
      before { mirrors.parse("mirror.http://rubygems.org/", localhost_uri) }

      context "without a fallback timeout" do

        it "returns the source uri that is not mirrored" do
          expect(mirrors.for("http://whatever.com").uri).to eq(URI("http://whatever.com/"))
        end

        it "returns mirror uri" do
          expect(mirrors.for("http://rubygems.org/").uri).to eq(localhost_uri)
        end
      end

      context "with a fallback timeout" do
        before { mirrors.parse("mirror.http://rubygems.org/.fallback_timeout", "true") }

        it "returns the source uri that is not mirrored" do
          expect(mirrors.for("http://whatever.com").uri).to eq(URI("http://whatever.com/"))
        end

        it "returns uri that is mirrored not the mirror" do
          expect(mirrors.for("http://rubygems.org/").uri).to eq(URI("http://rubygems.org/"))
        end
      end
    end
  end
end
