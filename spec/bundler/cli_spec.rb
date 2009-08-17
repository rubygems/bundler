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

      Dir.chdir(tmp_dir) do
        @output = gem_command :bundle
      end
    end

    it "caches and installs rake" do
      gems = %w(rake-0.8.7 extlib-0.9.12 rack-0.9.1 very-simple-1.0)
      tmp_file("vendor", "gems").should have_cached_gems(*gems)
      tmp_file("vendor", "gems").should have_installed_gems(*gems)
    end

    it "creates a default environment file with the appropriate load paths" do
      tmp_file('vendor', 'gems', 'environments', 'default.rb').should have_load_paths(tmp_file("vendor", "gems"),
        "extlib-0.9.12" => %w(lib),
        "rake-0.8.7" => %w(bin lib),
        "very-simple-1.0" => %w(bin lib)
      )

      tmp_file('vendor', 'gems', 'environments', 'web.rb').should have_load_paths(tmp_file("vendor", "gems"),
        "extlib-0.9.12" => %w(lib),
        "rake-0.8.7" => %w(bin lib),
        "rack-0.9.1" => %w(bin lib),
        "very-simple-1.0" => %w(bin lib)
      )
    end

    it "creates an executable for rake in ./bin" do
      out = run_in_context "puts $:"
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "lib").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "bin").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "extlib-0.9.12", "lib").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "very-simple-1.0", "lib").to_s)
      out.should_not include(tmp_file("vendor", "gems", "gems", "rack-0.9.1").to_s)
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

  describe "it working while specifying the manifest file name" do
    it "works when the manifest is in the root directory" do
      build_manifest_file tmp_file('manifest.rb'), <<-Gemfile
        bundle_path "gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(tmp_file)
      gem_command :bundle, "-m #{tmp_file('manifest.rb')}"
      tmp_file("gems").should have_cached_gems("rake-0.8.7")
    end

    it "works when the manifest is in a different directory" do
      build_manifest_file tmp_file('config', 'manifest.rb'), <<-Gemfile
        bundle_path "../gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(tmp_file)
      gem_command :bundle, "-m #{tmp_file('config', 'manifest.rb')}"
      tmp_file("gems").should have_cached_gems("rake-0.8.7")
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

      Dir.chdir(tmp_dir) do
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

      Dir.chdir(tmp_dir) do
        gem_command :bundle, "--update"
      end
      tmp_file("vendor", "gems").should have_cached_gems("rack-1.0.0")
      tmp_file("vendor", "gems").should have_installed_gems("rack-1.0.0")
    end
  end
end
