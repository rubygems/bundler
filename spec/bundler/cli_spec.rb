require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::CLI" do
  describe "it working" do
    before(:each) do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
        gem "extlib"
        gem "very-simple"
        gem "rack", :only => :web
      Gemfile

      Dir.chdir(bundled_app) do
        @output = gem_command :bundle
      end
    end

    it "caches and installs rake" do
      gems = %w(rake-0.8.7 extlib-0.9.12 rack-0.9.1 very-simple-1.0)
      bundled_app("vendor", "gems").should have_cached_gems(*gems)
      bundled_app("vendor", "gems").should have_installed_gems(*gems)
    end

    it "creates a default environment file with the appropriate load paths" do
      bundled_app('vendor', 'gems', 'environment.rb').should have_load_paths(bundled_app("vendor", "gems"),
        "extlib-0.9.12" => %w(lib),
        "rake-0.8.7" => %w(bin lib),
        "very-simple-1.0" => %w(bin lib),
        "rack-0.9.1" => %w(bin lib)
      )
    end

    it "creates an executable for rake in ./bin" do
      out = run_in_context "puts $:"
      out.should include(bundled_app("vendor", "gems", "gems", "rake-0.8.7", "lib").to_s)
      out.should include(bundled_app("vendor", "gems", "gems", "rake-0.8.7", "bin").to_s)
      out.should include(bundled_app("vendor", "gems", "gems", "extlib-0.9.12", "lib").to_s)
      out.should include(bundled_app("vendor", "gems", "gems", "very-simple-1.0", "lib").to_s)
      out.should include(bundled_app("vendor", "gems", "gems", "rack-0.9.1").to_s)
    end

    it "creates valid executables" do
      out = `#{bundled_app("bin", "rake")} -e 'require "extlib" ; puts Extlib'`.strip
      out.should == "Extlib"
    end

    it "runs exec correctly" do
      Dir.chdir(bundled_app) do
        out = gem_command :exec, %[ruby -e 'require "extlib" ; puts Extlib']
        out.should == "Extlib"
      end
    end

    it "maintains the correct environment when shelling out" do
      out = run_in_context "exec %{#{Gem.ruby} -e 'require %{very-simple} ; puts VerySimpleForTests'}"
      out.should == "VerySimpleForTests"
    end

    it "logs the correct information messages" do
      [ "Updating source: file:#{gem_repo1}",
        "Calculating dependencies...",
        "Downloading rake-0.8.7.gem",
        "Downloading extlib-0.9.12.gem",
        "Downloading rack-0.9.1.gem",
        "Downloading very-simple-1.0.gem",
        "Installing rake-0.8.7.gem",
        "Installing extlib-0.9.12.gem",
        "Installing rack-0.9.1.gem",
        "Installing very-simple-1.0.gem",
        "Done." ].each do |message|
          @output.should =~ /^#{Regexp.escape(message)}$/
        end
    end

    it "already has gems in the loaded_specs" do
      out = run_in_context "puts Gem.loaded_specs.key?('extlib')"
      out.should == "true"
    end

    it "does already has rubygems required" do
      out = run_in_context "puts Gem.respond_to?(:sources)"
      out.should == "true"
    end

    # TODO: Remove this when rubygems is fixed
    it "adds the gem to Gem.source_index" do
      out = run_in_context "puts Gem.source_index.find_name('very-simple').first.version"
      out.should == "1.0"
    end
  end

  describe "error cases" do
    before(:each) do
      bundled_app.mkdir_p
      Dir.chdir(bundled_app)
    end

    it "displays a friendly error message when there is no Gemfile" do
      out = gem_command :bundle
      out.should == "Could not find a Gemfile to use"
    end

    it "fails when a root level gem does not exist" do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "monk"
      Gemfile

      out = gem_command :bundle
      out.should include("Could not find gem 'monk (>= 0, runtime)' in any of the sources")
    end

    it "outputs a warning when a child gem dependency is missing dependencies" do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "treetop"
      Gemfile

      out = gem_command :bundle
      out.should include("Could not find gem 'polyglot (>= 0.2.5, runtime)' (required by 'treetop (>= 0, runtime)') in any of the sources")
    end
  end

  describe "it working while specifying the manifest file name" do
    it "works when the manifest is in the root directory" do
      build_manifest_file bundled_app('manifest.rb'), <<-Gemfile
        bundle_path "gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app)
      gem_command :bundle, "-m #{bundled_app('manifest.rb')}"
      bundled_app("gems").should have_cached_gems("rake-0.8.7")
    end

    it "works when the manifest is in a different directory" do
      build_manifest_file bundled_app('config', 'manifest.rb'), <<-Gemfile
        bundle_path "../gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app)
      gem_command :bundle, "-m #{bundled_app('config', 'manifest.rb')}"
      bundled_app("gems").should have_cached_gems("rake-0.8.7")
    end
  end

  describe "it working without rubygems" do
    before(:each) do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
        gem "extlib"
        gem "rack", :only => :web

        disable_rubygems
      Gemfile

      Dir.chdir(bundled_app) do
        @output = gem_command :bundle
      end
    end

    it "does not load rubygems when required" do
      out = run_in_context 'require "rubygems" ; puts Gem.respond_to?(:sources)'
      out.should == "false"
    end

    it "does not blow up if #gem is used" do
      out = run_in_context 'gem("merb-core") ; puts "Win!"'
      out.should == "Win!"
    end

    it "does not blow up if Gem errors are referred to" do
      out = run_in_context 'Gem::LoadError ; Gem::Exception ; puts "Win!"'
      out.should == "Win!"
    end

    it "stubs out Gem.ruby" do
      out = run_in_context "puts Gem.ruby"
      out.should == Gem.ruby
    end
  end

  describe "forcing an update" do
    it "forces checking for remote updates if --update is used" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rack", "0.9.1"
      Gemfile
      m.install

      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rack"
      Gemfile

      Dir.chdir(bundled_app) do
        gem_command :bundle, "--update"
      end
      bundled_app("vendor", "gems").should have_cached_gems("rack-1.0.0")
      bundled_app("vendor", "gems").should have_installed_gems("rack-1.0.0")
    end
  end
end
