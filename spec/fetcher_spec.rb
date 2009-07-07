require File.join(File.dirname(__FILE__), "spec_helper")

describe "Fetcher" do
  before(:each) do
    @source = URI.parse("file://#{File.expand_path(File.dirname(__FILE__))}/fixtures")
    @other  = URI.parse("file://#{File.expand_path(File.dirname(__FILE__))}/fixtures2")
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

  describe "resolving rails" do
    before(:each) do
      @tmp    = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))
      @bundle = @finder.resolve(build_dep('rails', '>= 0'))

      FileUtils.mkdir_p(File.join(@tmp, 'cache'))
      Dir[File.join(@tmp, 'cache', '*')].each { |file| FileUtils.rm_f(file) }
    end

    def fixture(gem_name)
      File.join(File.dirname(__FILE__), 'fixtures', 'gems', "#{gem_name}.gem")
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(@tmp, 'cache'))
    end

    def change
      simple_matcher("change") do |given, matcher|
        matcher.failure_message = "Expected the block to change, but it didn't"
        matcher.negative_failure_message = "Expected the block not to change, but it did"
        retval = yield
        given.call
        retval != yield
      end
    end

    def be_cached_at(dir)
      simple_matcher("the bundle should be cached") do |given|
        given.each do |spec|
          Dir[File.join(dir, 'cache', "#{spec.name}*.gem")].should have(1).item
        end
      end
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
      @bundle.download(@tmp)
      @bundle.should be_cached_at(@tmp)
    end

    it "does not download the gem if the gem is the same as the cached version" do
      copy("actionmailer-2.3.2")

      lambda {
        @bundle.download(@tmp)
        @bundle.should be_cached_at(@tmp)
      }.should_not change { File.mtime(fixture("actionmailer-2.3.2")) }
    end

    it "erases any gems in the directory that are not part of the bundle" do
      copy("abstract-1.0.0")
      @bundle.download(@tmp)

      Dir[File.join(@tmp, 'cache', '*.gem')].should have(@bundle.length).items
    end
  end
end