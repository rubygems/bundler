require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do

  def dep(name, version, options = {})
    Bundler::Dependency.new(name, {:version => version}.merge(options))
  end

  before(:each) do
    @sources = %W(file://#{gem_repo1} file://#{gem_repo2})
    @deps = []
    @deps << dep("rails", "2.3.2")
    @deps << dep("rack", "0.9.1")
  end

  describe "Manifest with dependencies" do

    before(:each) do
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails", "2.3.2"
        gem "rack",  "0.9.1"
      Gemfile
      @saved_load_path, @saved_loaded_features = $:.dup, $".dup
    end

    after(:each) do
      Object.send(:remove_const, :VerySimpleForTests) if defined?(VerySimpleForTests)
      $:.replace @saved_load_path
      $".replace @saved_loaded_features
    end

    it "bundles itself (running all of the steps)" do
      @manifest.install

      gems = %w(rack-0.9.1 actionmailer-2.3.2
        activerecord-2.3.2 activesupport-2.3.2
        rake-0.8.7 actionpack-2.3.2
        activeresource-2.3.2 rails-2.3.2)

      tmp_gem_path.should have_cached_gems(*gems)
      tmp_gem_path.should have_installed_gems(*gems)
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

      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails", "2.3.2"
        gem "rack",  "1.0.0"
      Gemfile

      m.install

      gems = %w(rack-1.0.0 actionmailer-2.3.2
        activerecord-2.3.2 activesupport-2.3.2
        rake-0.8.7 actionpack-2.3.2
        activeresource-2.3.2 rails-2.3.2)

      tmp_gem_path.should have_cached_gems(*gems)
      tmp_gem_path.should have_installed_gems(*gems)
    end

    it "removes gems that are not needed anymore" do
      @manifest.install
      tmp_gem_path.should include_cached_gem("rack-0.9.1")
      tmp_gem_path.should include_installed_gem("rack-0.9.1")
      tmp_bindir("rackup").should exist

      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails", "2.3.2"
      Gemfile

      m.install

      tmp_gem_path.should_not include_cached_gem("rack-0.9.1")
      tmp_gem_path.should_not include_installed_gem("rack-0.9.1")
      tmp_bindir("rackup").should_not exist
      @log_output.should have_log_message("Deleting gem: rack-0.9.1")
      @log_output.should have_log_message("Deleting bin file: rackup")
    end

    it "removes stray specfiles" do
      spec = tmp_gem_path("specifications", "omg.gemspec")
      FileUtils.mkdir_p(tmp_gem_path("specifications"))
      FileUtils.touch(spec)
      @manifest.install
      spec.should_not exist
    end

    it "removes any stray directories in gems that are not to be installed" do
      dir = tmp_gem_path("gems", "omg")
      FileUtils.mkdir_p(dir)
      @manifest.install
      dir.should_not exist
    end

    it "raises a friendly exception if the manifest doesn't resolve" do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails", "2.3.2"
        gem "rack",  "0.9.1"
        gem "active_support", "2.0"
      Gemfile
      Dir.chdir(tmp_dir)

      lambda do
        Bundler::CLI.run(:bundle)
      end.should raise_error(SystemExit)

      @log_output.should have_log_message(/rails \(= 2\.3\.2.*rack \(= 0\.9\.1.*active_support \(= 2\.0/m)
    end
  end

  describe "runtime" do

    it "is able to work system gems" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple"
      Gemfile

      out = run_in_context "require 'rake' ; puts Rake"
      out.should == "Rake"
    end

    it "it does not work with system gems if system gems have been disabled" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple"
        disable_system_gems
      Gemfile

      m.install
      out = run_in_context "begin ; require 'rake' ; rescue LoadError ; puts('WIN') ; end"
      out.should == "WIN"
    end

    ["Running with system gems", "Running without system gems"].each_with_index do |desc, i|
      describe desc do
        before(:each) do
          m = build_manifest <<-Gemfile
            clear_sources
            source "file://#{gem_repo1}"
            gem "very-simple"
            #{'disable_system_gems' if i == 1}
          Gemfile
          m.install
        end

        it "sets loaded_from on the specs" do
          out = run_in_context "puts(Gem.loaded_specs['very-simple'].loaded_from || 'FAIL')"
          out.should_not == "FAIL"
        end

        it "finds the gems in the source_index" do
          out = run_in_context "puts Gem.source_index.find_name('very-simple').length"
          out.should == "1"
        end

        it "still finds the gems in the source_index even if refresh! is called" do
          out = run_in_context "Gem.source_index.refresh! ; puts Gem.source_index.find_name('very-simple').length"
          out.should == "1"
        end
      end
    end
  end

  describe "environments" do
    before(:each) do
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "very-simple", "1.0.0", :only => "testing"
        gem "rack",        "1.0.0"
      Gemfile

      @manifest.install
      @manifest = @manifest.manifest
    end

    it "can provide a list of environments" do
      @manifest.environments.should == ["testing", "default"]
    end

    it "requires the Rubygems library" do
      out = run_in_context "puts 'Gem'"
      out.should == "Gem"
    end

    it "Gem.loaded_specs has the gems that are included" do
      out = run_in_context %'puts Gem.loaded_specs.map{|k,v|"\#{k} - \#{v.version}"}'
      out.should include("rack - 1.0.0")
    end

    it "Gem.loaded_specs has the gems that are included in the testing environment" do
      env = tmp_gem_path('environments', 'default.rb')
      out = run_in_context env, %'puts Gem.loaded_specs.map{|k,v|"\#{k} - \#{v.version}"}'
      out.should include("rack - 1.0.0")
      out.should include("very-simple - 1.0")
    end
  end
end
