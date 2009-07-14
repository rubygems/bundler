require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do

  def dep(name, version)
    Bundler::Dependency.new(name, :version => version)
  end

  before(:each) do
    @sources = %W(file://#{gem_repo1} file://#{gem_repo2})
    @deps = []
    @deps << dep("rails", "2.3.2")
    @deps << dep("rack", "0.9.1")

    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    @manifest = Bundler::Manifest.new(@sources, @deps, tmp_dir)
  end

  after(:each) do
    Object.send(:remove_const, :VerySimpleForTests) if defined?(VerySimpleForTests)
    $:.delete_if {|p| p =~ /very-simple/ }
    $".delete("very-simple.rb")
  end

  it "has a list of sources and dependencies" do
    @manifest.sources.should == @sources
    @manifest.dependencies.should == @deps
  end

  def have_cached_gems(*gems)
    simple_matcher("have cached gems") do |given, matcher|
      gems.all? do |name|
        matcher.failure_message = "Gem #{name} was not cached"
        File.exists?(File.join(given, "cache", "#{name}.gem"))
      end
    end
  end

  alias have_cached_gem have_cached_gems

  def have_installed_gems(*gems)
    simple_matcher("have installed gems") do |given, matcher|
      gems.all? do |name|
        matcher.failure_message = "Gem #{name} was not installed"
        File.exists?(File.join(given, "specifications", "#{name}.gemspec")) &&
        File.directory?(File.join(given, "gems", "#{name}"))
      end
    end
  end

  alias have_installed_gem have_installed_gems

  it "bundles itself (running all of the steps)" do
    @manifest.install

    gems = %w(rack-0.9.1 actionmailer-2.3.2
      activerecord-2.3.2 activesupport-2.3.2
      rake-0.8.7 actionpack-2.3.2
      activeresource-2.3.2 rails-2.3.2)

    tmp_dir.should have_cached_gems(*gems)
    tmp_dir.should have_installed_gems(*gems)
  end

  it "skips fetching the source index if all gems are present" do
    @manifest.install
    Bundler::Finder.should_not_receive(:new)
    @manifest.install
  end

  it "does the full fetching if a gem in the cache does not match the manifest" do
    @manifest.install

    deps = []
    deps << dep("rails", "2.3.2")
    deps << dep("rack", "1.0.0")

    manifest = Bundler::Manifest.new(@sources,deps, tmp_dir)
    manifest.install

    gems = %w(rack-1.0.0 actionmailer-2.3.2
      activerecord-2.3.2 activesupport-2.3.2
      rake-0.8.7 actionpack-2.3.2
      activeresource-2.3.2 rails-2.3.2)

    tmp_dir.should have_cached_gems(*gems)
    tmp_dir.should have_installed_gems(*gems)
  end

  it "raises a friendly exception if the manifest doesn't resolve" do
    @manifest.dependencies << dep("active_support", "2.0")

    lambda { @manifest.install }.should raise_error(Bundler::VersionConflict,
      /rails \(= 2\.3\.2.*rack \(= 0\.9\.1.*active_support \(= 2\.0/m)
  end

  describe "runtime" do
    it "makes gems available via Manifest#activate" do
      manifest = Bundler::Manifest.new(@sources, [dep("very-simple", "1.0.0")], tmp_dir)
      manifest.install

      manifest.activate
      $:.any? do |p|
        File.expand_path(p) == File.expand_path(tmp_file("gems", "very-simple-1.0", "lib"))
      end.should be_true
    end

    it "makes gems available" do
      manifest = Bundler::Manifest.new(@sources, [dep("very-simple", "1.0.0")], tmp_dir)
      manifest.install

      manifest.activate
      manifest.require_all

      $".any? do |f|
        File.expand_path(f) ==
          File.expand_path(tmp_file("gems", "very-simple-1.0", "lib", "very-simple.rb"))
      end
    end
  end

end