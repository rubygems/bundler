require 'spec_helper'

describe Bundler::Source::Rubygems do
  before do
    Bundler.stub(:root){ Pathname.new("root") }
  end

  describe "caches" do
    it "should include Bundler.app_cache" do
      subject.caches.should include(Bundler.app_cache)
    end

    it "should include GEM_PATH entries" do
      Gem.path.each do |path|
        subject.caches.should include(File.expand_path("#{path}/cache"))
      end
    end

    it "should be an array of strings or pathnames" do
      subject.caches.each do |cache|
        [String, Pathname].should include(cache.class)
      end
    end
  end
end
