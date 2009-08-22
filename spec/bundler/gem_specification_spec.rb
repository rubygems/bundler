require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Gem::Specification" do

  it "is able to store the source URI of the gem as a URI" do
    spec = Gem::Specification.new do |s|
      s.name    = 'greeter'
      s.version = '1.0'
      s.source  = 'http://gems.rubyforge.org'
    end

    spec.source.should == Bundler::Source.new(:uri => "http://gems.rubyforge.org")
  end

  it "does not consider two gem specs with different sources to be the same" do
    pending "Do we want to keep this?"
    spec1 = Gem::Specification.new do |s|
      s.name    = 'greeter'
      s.version = '1.0'
      s.source  = 'http://gems.rubyforge.org'
    end

    spec2 = spec1.dup
    spec2.source = Bundler::Source.new(:uri => "http://gems.github.com")

    spec1.should_not == spec2
  end

  it "can set a source that is already a Source" do
    source = Bundler::Source.new(:uri => "http://foo")
    spec   = Gem::Specification.new
    spec.source = source
    spec.source.should == source
  end

  it "requires a valid URI for the source" do
    spec = Gem::Specification.new
    lambda { spec.source = "fail" }.should raise_error(ArgumentError)
  end

end