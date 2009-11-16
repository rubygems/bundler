require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Environment" do

  describe "Manifest with dependencies" do

    before :each do
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rails", "2.3.2"
        gem "rack",  "0.9.1"
      Gemfile
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
      Dir.chdir(bundled_app) do
        gem_command :bundle
        lambda { sleep 0.1 ; gem_command :bundle }.should_not change { File.stat(gem_repo1.join("Marshal.4.8.Z")).atime }
      end
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
        gem "rails", "2.3.2"
        gem "rack",  "1.0.0"
      Gemfile

      m.install

      gems = %w(rack-1.0.0 actionmailer-2.3.2
        activerecord-2.3.2 activesupport-2.3.2
        rake-0.8.7 actionpack-2.3.2
        activeresource-2.3.2 rails-2.3.2)

      # Keeps cached gems
      tmp_gem_path.should have_cached_gems(*(gems + ["rack-0.9.1"]))
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
        gem "rails", "2.3.2"
      Gemfile

      m.install

      # Gem caches are not removed
      tmp_gem_path.should include_cached_gem("rack-0.9.1")
      tmp_gem_path.should_not include_installed_gem("rack-0.9.1")
      tmp_bindir("rackup").should_not exist
      @log_output.should have_log_message("Deleting gem: rack (0.9.1)")
      @log_output.should have_log_message("Deleting bin file: rackup")
    end

    it "raises a friendly exception if the manifest doesn't resolve" do
      pending
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
        gem "rack"
      Gemfile

      out = run_in_context "require 'rake' ; puts Rake"
      out.should == "Rake"
    end

    it "it does not work with system gems if system gems have been disabled" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack"
        disable_system_gems
      Gemfile

      m.install
      out = run_in_context "begin ; require 'spec' ; rescue LoadError ; puts('WIN') ; end"
      out.should == "WIN"
    end

    ["Running with system gems", "Running without system gems"].each_with_index do |desc, i|
      describe desc do
        before(:each) do
          m = build_manifest <<-Gemfile
            clear_sources
            source "file://#{gem_repo1}"
            gem "rake"
            #{'disable_system_gems' if i == 1}
          Gemfile
          m.install
        end

        it "sets loaded_from on the specs" do
          out = run_in_context "puts(Gem.loaded_specs['rake'].loaded_from || 'FAIL')"
          out.should_not == "FAIL"
        end

        it "finds the gems in the source_index" do
          out = run_in_context "puts Gem.source_index.find_name('rake').length"
          out.should == "1"
        end

        it "still finds the gems in the source_index even if refresh! is called" do
          out = run_in_context "Gem.source_index.refresh! ; puts Gem.source_index.find_name('rake').length"
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
        gem "rake", :only => "testing"
        gem "rack", "1.0.0"
      Gemfile

      @manifest.install
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
      out = run_in_context %'puts Gem.loaded_specs.map{|k,v|"\#{k} - \#{v.version}"}'
      out.should include("rack - 1.0.0")
      out.should include("rake - 0.8.7")
    end
  end
end
