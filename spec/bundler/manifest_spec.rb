require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do

  def dep(name, version, options = {})
    Bundler::Dependency.new(name, {:version => version}.merge(options))
  end

  before(:all) do
    @sources = %W(file://#{gem_repo1} file://#{gem_repo2})
    @deps = []
    @deps << dep("rails", "2.3.2")
    @deps << dep("rack", "0.9.1")
  end

  describe "Manifest with dependencies" do

    before(:each) do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      @manifest = Bundler::Manifest.new(@sources, @deps, tmp_dir)
      @saved_load_path, @saved_loaded_features = $:.dup, $".dup
    end

    after(:each) do
      Object.send(:remove_const, :VerySimpleForTests) if defined?(VerySimpleForTests)
      $:.replace @saved_load_path
      $".replace @saved_loaded_features
    end

    it "has a list of sources and dependencies" do
      @manifest.sources.should == @sources
      @manifest.dependencies.should == @deps
    end

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

    it "logs 'Done' when done" do
      @manifest.install
      @log_output.should have_log_message("Done.")
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
  end

  describe "runtime" do
    before(:each) do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
    end

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

  describe "environments" do
    before(:all) do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      @manifest = Bundler::Manifest.new(@sources,
        [dep("very-simple", "1.0.0", :only => "testing"),
         dep("rack", "1.0.0")], tmp_dir)

      @manifest.install
    end

    it "can provide a list of environments" do
      @manifest.environments.should == ["testing", "default"]
    end

    it "knows what gems are in an environment" do
      @manifest.gems_for("testing").should match_gems(
        "very-simple" => ["1.0"], "rack" => ["1.0.0"])

      @manifest.gems_for("production").should match_gems(
        "rack" => ["1.0.0"])
    end

    it "can create load path files for each environment" do
      tmp_file('environments', 'testing.rb').should have_load_paths(tmp_dir,
        "very-simple-1.0" => %w(bin lib),
        "rack-1.0.0"      => %w(bin lib)
      )

      tmp_file('environments', 'default.rb').should have_load_paths(tmp_dir,
        "rack-1.0.0" => %w(bin lib)
      )

      File.exist?(tmp_file('environments', "production.rb")).should be_false
    end

    it "adds the environments path to the load paths" do
      tmp_file('environments', 'testing.rb').should have_load_paths(tmp_dir, [
        "environments"
      ])
    end

    it "creates a rubygems.rb file in the environments directory" do
      File.exist?(tmp_file('environments', 'rubygems.rb')).should be_true
    end

    it "requires the Rubygems library" do
      env = tmp_file('environments', 'default.rb')
      out = `#{Gem.ruby} -r #{env} -r rubygems -e 'puts Gem'`.strip
      out.should == 'Gem'
    end

    it "removes the environments path from the load paths after rubygems is required" do
      env = tmp_file('environments', 'default.rb')
      out = `#{Gem.ruby} -r #{env} -r rubygems -e 'puts $:'`
      out.should_not include(tmp_file('environments'))
    end

    it "Gem.loaded_specs has the gems that are included" do
      env = tmp_file('environments', 'default.rb')
      out = `#{Gem.ruby} -r #{env} -r rubygems -e 'puts Gem.loaded_specs.map{|k,v|"\#{k} - \#{v.version}"}'`
      out = out.split("\n")
      out.should include("rack - 1.0.0")
    end

    it "Gem.loaded_specs has the gems that are included in the testing environment" do
      env = tmp_file('environments', 'testing.rb')
      out = `#{Gem.ruby} -r #{env} -r rubygems -e 'puts Gem.loaded_specs.map{|k,v|"\#{k} - \#{v.version}"}'`
      out = out.split("\n")
      out.should include("rack - 1.0.0")
      out.should include("very-simple - 1.0")
    end
  end
end