require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::CLI" do

  describe "it compiles gems that take options" do
    before(:each) do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very_simple_binary"
      Gemfile

      File.open("#{bundled_app}/build.yml", "w+") do |file|
        file.puts <<-build_options.gsub(/^          /, '')
          very_simple_binary:
            simple: wot
        build_options
      end
    end

    it "fails if the option is not provided" do
      Dir.chdir(bundled_app) do
        @output = gem_command :bundle, "2>&1"
      end

      @output.should =~ /Failed to build gem native extension/
    end

    it "passes if a yaml is specified that contains the necessary options" do
      Dir.chdir(bundled_app) do
        @output = gem_command :bundle, "--build-options=build.yml 2>&1"
      end

      @output.should_not =~ /Failed to build gem native extension/

      out = run_in_context <<-RUBY
        require 'very_simple_binary_c'
        puts VerySimpleBinaryInC
      RUBY

      out.should == "VerySimpleBinaryInC"
    end

    it "does not skip the binary gem if compiling failed in a previous bundle" do
      Dir.chdir(bundled_app)

      gem_command :bundle, "--backtrace 2>&1" # will fail
      gem_command :bundle, "--build-options=build.yml 2>&1"

      out = run_in_context <<-RUBY
        require "very_simple_binary_c"
        puts VerySimpleBinaryInC
      RUBY
      out.should == "VerySimpleBinaryInC"
    end
  end

  describe "it working" do
    before :each do
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
        gem "activesupport"
        gem "rack", :only => :web
      Gemfile

      Dir.chdir(bundled_app) do
        @output = gem_command :bundle
      end
    end

    it "caches and installs rake" do
      gems = %w(rake-0.8.7 activesupport-2.3.2 rack-1.0.0)
      @manifest.gem_path.should have_cached_gems(*gems)
      @manifest.gem_path.should have_installed_gems(*gems)
    end

    it "creates a default environment file with the appropriate load paths" do
      out = run_in_context <<-RUBY
        require "rake"
        require "activesupport"
        require "rack"
        puts "\#{RAKE} - \#{ACTIVESUPPORT} - \#{RACK}"
      RUBY

      out.should == "0.8.7 - 2.3.2 - 1.0.0"
    end

    it "creates a platform-independent environment picker" do
      @manifest.gem_path.join('../../environment.rb').file?.should == true
    end

    it "creates valid executables in ./bin" do
      app_root do
        `bin/rake`.should == "0.8.7\n"
      end
    end

    it "runs exec correctly" do
      app_root do
        out = gem_command :exec, %[ruby -e 'require "rake" ; puts RAKE']
        out.should == "0.8.7"
      end
    end

    it "runs exec with options correctly" do
      Dir.chdir(bundled_app) do
        out = gem_command :exec, %[ruby -e 'puts "hello"'], :no_quote => true
        out.should == "hello"
      end
    end

    it "maintains the correct environment when shelling out" do
      out = run_in_context "exec %{#{Gem.ruby} -e 'require %{rake} ; puts RAKE'}"
      out.should == "0.8.7"
    end

    it "logs the correct information messages" do
      [ "Updating source: file:#{gem_repo1}",
        "Calculating dependencies...",
        "Downloading rake-0.8.7.gem",
        "Downloading activesupport-2.3.2.gem",
        "Downloading rack-1.0.0.gem",
        "Installing rake (0.8.7)",
        "Installing activesupport (2.3.2)",
        "Installing rack (1.0.0)",
        "Done." ].each do |message|
          @output.should =~ /^#{Regexp.escape(message)}$/
        end
    end

    it "already has gems in the loaded_specs" do
      out = run_in_context "puts Gem.loaded_specs.key?('activesupport')"
      out.should == "true"
    end

    it "does already has rubygems required" do
      out = run_in_context "puts Gem.respond_to?(:sources)"
      out.should == "true"
    end

    # TODO: Remove this when rubygems is fixed
    it "adds the gem to Gem.source_index" do
      out = run_in_context "puts Gem.source_index.find_name('activesupport').first.version"
      out.should == "2.3.2"
    end
  end

  describe "error cases" do
    before :each do
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
        gem "missing_dep"
      Gemfile

      out = gem_command :bundle
      out.should include("Could not find gem 'not_here (>= 0, runtime)' (required by 'missing_dep (>= 0, runtime)') in any of the sources")
    end
  end

  it "raises when providing a bad manifest" do
    out = gem_command :bundle, "-m manifest_not_here"
    out.should =~ /Manifest file not found: \".*manifest_not_here\"/
  end

  describe "it working while specifying the manifest file name" do
    it "works when the manifest is in the root directory" do
      manifest = build_manifest bundled_app('manifest.rb'), <<-Gemfile
        bundle_path "gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "-m #{bundled_app('manifest.rb')}"
        out.should include('Done.')
        manifest.gem_path.should have_cached_gems("rake-0.8.7")
        tmp_bindir('rake').should exist
      end
    end

    it "works when the manifest is in a different directory" do
      manifest = build_manifest bundled_app('config', 'manifest.rb'), <<-Gemfile
        bundle_path "../gems"
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app)
      out = gem_command :bundle, "-m #{bundled_app('config', 'manifest.rb')}"
      out.should include('Done.')
      manifest.gem_path.should have_cached_gems("rake-0.8.7")
    end

    it "works when using a relative path to the manifest file" do
      build_manifest_file bundled_app('manifest_file'), <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "-m manifest_file"
        out.should include('Done.')
        tmp_gem_path.should have_cached_gems("rake-0.8.7")
        tmp_bindir('rake').should exist
      end
    end
  end

  describe "it working without rubygems" do
    before(:each) do
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rake"
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

    it "stubs out Gem.dir" do
      out = run_in_context "puts Gem.dir"
      out.should == @manifest.gem_path.to_s
    end

    it "stubs out Gem.default_dir" do
      out = run_in_context "puts Gem.default_dir"
      out.should == @manifest.gem_path.to_s
    end

    it "stubs out Gem.path" do
      out = run_in_context "puts Gem.path"
      out.should == @manifest.gem_path.to_s
    end
  end

  describe "relative paths everywhere" do
    it "still works when you move the app directory" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack"
      Gemfile

      FileUtils.mv bundled_app, tmp_path("bundled_app2")

      Dir.chdir(tmp_path('bundled_app2')) do
        out = gem_command :exec, "ruby -e 'Bundler.require_env :default ; puts RACK'"
        out.should == "1.0.0"
        `bin/rackup`.strip.should == "1.0.0"
      end
    end
  end

  describe "forcing an update" do
    it "forces checking for remote updates if --update is used" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      Gemfile
      m.install

      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack"
      Gemfile

      Dir.chdir(bundled_app) do
        gem_command :bundle, "--update"
      end
      m.gem_path.should include_cached_gems("rack-1.0.0")
      m.gem_path.should have_installed_gems("rack-1.0.0")
    end
  end

  describe "bundling from the local cache" do
    before(:each) do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      Gemfile

      %w(doc environment.rb gems specifications).each do |f|
        FileUtils.rm_rf(tmp_gem_path.join(f))
      end
    end

    it "only uses the localy cached gems when bundling with --cache" do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack"
      Gemfile

      Dir.chdir(bundled_app) do
        gem_command :bundle, "--cached"
        tmp_gem_path.should include_cached_gems("rack-0.9.1")
        tmp_gem_path.should have_installed_gems("rack-0.9.1")
      end
    end

    it "raises an exception when there are missing gems in the cache" do
      Dir["#{tmp_gem_path}/cache/*"].each { |f| FileUtils.rm_rf(f) }

      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack"
      Gemfile

      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "--cached"
        out.should include("Could not find gem 'rack (>= 0, runtime)' in any of the sources")
        tmp_gem_path.should_not include_cached_gems("rack-0.9.1", "rack-1.0.0")
        tmp_gem_path.should_not include_installed_gems("rack-0.9.1", "rack-1.0.0")
      end
    end
  end

  describe "bundling only given environments" do
    before(:each) do
      build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "activesupport"
        gem "very-simple", :only => :server
        gem "rack", :only => :test
      Gemfile
    end

    it "install gems for environments specified in --only line" do
      system_gems do
        app_root do
          gem_command :bundle, "--only test"
          out = run_in_context "require 'activesupport' ; require 'rack' ; puts ACTIVESUPPORT"
          out.should == "2.3.2"

          out = run_in_context <<-RUBY
            begin ;require 'very-simple'
            rescue LoadError ; puts 'awesome' ; end
          RUBY
          out.should == 'awesome'
        end
      end
    end
  end

  describe "caching gems to the bundle" do
    before(:each) do
      build_manifest <<-Gemfile
        clear_sources
      Gemfile
    end

    it "adds a single gem to the cache" do
      build_manifest <<-Gemfile
        clear_sources
        gem "rack"
      Gemfile

      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "--cache #{gem_repo1}/gems/rack-0.9.1.gem"
        gem_command :bundle, "--cached"
        out.should include("Caching: rack-0.9.1.gem")
        tmp_gem_path.should include_cached_gems("rack-0.9.1")
        tmp_gem_path.should include_installed_gems("rack-0.9.1")
      end
    end

    it "adds a gem directory to the cache" do
      m = build_manifest <<-Gemfile
        clear_sources
        gem "rack"
        gem "activesupport"
      Gemfile

      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "--cache #{gem_repo1}/gems"
        gem_command :bundle, "--cached"

        %w(actionmailer-2.3.2 activerecord-2.3.2 rake-0.8.7 rack-0.9.1 rack-1.0.0).each do |gemfile|
          out.should include("Caching: #{gemfile}.gem")
        end
        m.gem_path.should include_cached_gems("rack-1.0.0", "activesupport-2.3.2")
        m.gem_path.should have_installed_gems("rack-1.0.0", "activesupport-2.3.2")
      end
    end

    it "adds a gem from the local repository" do
      system_gems "rake-0.8.7" do
        build_manifest <<-Gemfile
          clear_sources
          gem "rake"
          disable_system_gems
        Gemfile

        Dir.chdir(bundled_app) do
          # out = gem_command :bundle, "--cache rake"
          gem_command :bundle
          out = run_in_context "require 'rake' ; puts RAKE"
          out.should == "0.8.7"
        end
      end
    end

    it "outputs an error when trying to cache a gem that doesn't exist." do
      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "--cache foo/bar.gem"
        out.should == "'foo/bar.gem' does not exist."
      end
    end

    it "outputs an error when trying to cache a directory that doesn't exist." do
      Dir.chdir(bundled_app) do
        out = gem_command :bundle, "--cache foo/bar"
        out.should == "'foo/bar' does not exist."
      end
    end

    it "outputs an error when trying to cache a directory with no gems." do
      Dir.chdir(bundled_app) do
        FileUtils.mkdir_p("foo/bar")
        out = gem_command :bundle, "--cache foo/bar"
        out.should == "'foo/bar' contains no gemfiles"
      end
    end
  end

  describe "pruning the cache" do
    it "works" do
      manifest = install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      Gemfile

      manifest.gem_path.should have_cached_gems("rack-0.9.1")

      manifest = install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
      Gemfile

      manifest.gem_path.should have_cached_gems("rack-0.9.1")
      Dir.chdir bundled_app
      out = gem_command :bundle, "--prune-cache"
      manifest.gem_path.should_not have_cached_gems("rack-0.9.1")
    end
  end

  describe "listing gems" do
    it "works" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      Gemfile

      Dir.chdir bundled_app
      out = gem_command :bundle, "--list"
      out.should =~ /rack/
    end
  end

  describe "listing outdated gems" do
    it "shows a message when there are no outdated gems" do
      m = build_manifest <<-Gemfile
        clear_sources
      Gemfile
      m.install

      Dir.chdir(bundled_app) do
        @output = gem_command :bundle, "--list-outdated"
      end

      @output.should =~ /All gems are up to date/
    end

    it "shows all the outdated gems" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
        gem "rails"
      Gemfile
      m.install

      app_root do
        @output = gem_command :bundle, "--list-outdated"
      end

      [ "Outdated gems:",
        " * actionmailer",
        " * actionpack",
        " * activerecord",
        " * activeresource",
        " * activesupport",
        " * rack",
        " * rails"].each do |message|
          @output.should =~ /^#{Regexp.escape(message)}$/
        end
    end
  end
end
