require File.join(File.dirname(__FILE__), "/../spec_helper")

describe "Fetcher" do
  before(:each) do
    @source = URI.parse("file://#{fixtures1}")
    @other  = URI.parse("file://#{fixtures2}")
    @finder = Bundler::Finder.new(@source, @other)
  end

  it "stashes the source in the returned gem specification" do
    @finder.search(Gem::Dependency.new("abstract", ">= 0")).first.source.should == @source
  end

  it "uses the first source that was passed in if multiple sources have the same gem" do
    @finder.search(build_dep("activerecord", "= 2.3.2")).first.source.should == @source
  end

  it "raises if the source is invalid" do
    lambda { Bundler::Finder.new.fetch("file://not/a/gem/source") }.should raise_error(ArgumentError)
    lambda { Bundler::Finder.new.fetch("http://localhost") }.should raise_error(ArgumentError)
    lambda { Bundler::Finder.new.fetch("http://google.com/not/a/gem/location") }.should raise_error(ArgumentError)
  end

  it "accepts multiple source indexes" do
    @finder.search(Gem::Dependency.new("abstract", ">= 0")).size.should == 1
    @finder.search(Gem::Dependency.new("merb-core", ">= 0")).size.should == 2
  end

  it "does not include gems that don't match the current platform" do
    begin
      Gem.platforms = [Gem::Platform::RUBY]
      finder = Bundler::Finder.new(@source)
      finder.search(build_dep("do_sqlite3", "> 0")).should only_have_specs("do_sqlite3-0.9.11")

      # Try out windows
      Gem.platforms = [Gem::Platform.new("mswin32_60")]
      finder = Bundler::Finder.new(@source)
      finder.search(build_dep("do_sqlite3", "> 0")).should only_have_specs("do_sqlite3-0.9.12-x86-mswin32-60")
    ensure
      Gem.platforms = nil
    end
  end

  describe "resolving rails" do
    before(:each) do
      @bundle = @finder.resolve(build_dep('rails', '>= 0'))

      FileUtils.mkdir_p(File.join(tmp_dir, 'cache'))
      Dir[File.join(tmp_dir, 'cache', '*')].each { |file| FileUtils.rm_f(file) }
    end

    it "resolves rails" do
      @bundle.should match_gems(
        "rails"          => ["2.3.2"],
        "actionpack"     => ["2.3.2"],
        "actionmailer"   => ["2.3.2"],
        "activerecord"   => ["2.3.2"],
        "activeresource" => ["2.3.2"],
        "activesupport"  => ["2.3.2"],
        "rake"           => ["0.8.7"]
      )
    end

    it "keeps track of the source that the gem spec was found in" do
      @bundle.select { |spec| spec.name == "activeresource" && spec.source == @other }.should have(1).item
      @bundle.select { |spec| spec.name == "activerecord" && spec.source == @source }.should have(1).item
    end

    it "can download the bundle" do
      @bundle.download(tmp_dir)
      @bundle.should be_cached_at(tmp_dir)
    end

    it "does not download the gem if the gem is the same as the cached version" do
      copy("actionmailer-2.3.2")

      lambda {
        @bundle.download(tmp_dir)
        @bundle.should be_cached_at(tmp_dir)
      }.should_not change { File.mtime(fixture("actionmailer-2.3.2")) }
    end

    it "erases any gems in the directory that are not part of the bundle" do
      copy("abstract-1.0.0")
      @bundle.download(tmp_dir)

      Dir[File.join(tmp_dir, 'cache', '*.gem')].should have(@bundle.length).items
    end
  end
end