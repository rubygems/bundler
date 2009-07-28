require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::CLI" do
  describe "it working" do
    before(:each) do
      build_manifest <<-Gemfile
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
        gem "extlib"
        gem "very-simple"
        gem "rack", :only => :web
      Gemfile

      lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
      bin = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'gem_bundler'))

      Dir.chdir(tmp_dir) do
        @output = `#{Gem.ruby} -I #{lib} #{bin}`
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
      out = `#{tmp_file('bin', 'rake')} -e 'puts $:'`
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "lib").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "bin").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "extlib-0.9.12", "lib").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "very-simple-1.0", "lib").to_s)
      out.should_not include(tmp_file("vendor", "gems", "gems", "rack-0.9.1").to_s)
    end

    it "maintains the correct environment when shelling out" do
      File.open(tmp_file("Rakefile"), 'w') do |f|
        f.puts <<-RAKE
task :hello do
  exec %{#{Gem.ruby} -e 'require "very-simple" ; puts VerySimpleForTests'}
end
        RAKE
      end
      Dir.chdir(tmp_dir) do
        out = `#{tmp_file("bin", "rake")} hello`
        out.should == "VerySimpleForTests\n"
      end
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
  end

  describe "it working while specifying the manifest file name" do
    it "works when the manifest is in the root directory" do
      build_manifest_file tmp_file('manifest.rb'), <<-Gemfile
        bundle_path "gems"
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(tmp_file)
      Bundler::CLI.run(["-m", tmp_file('manifest.rb').to_s])
      tmp_file("gems").should have_cached_gems("rake-0.8.7")
    end

    it "works when the manifest is in a different directory" do
      build_manifest_file tmp_file('config', 'manifest.rb'), <<-Gemfile
        bundle_path "../gems"
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
      Gemfile

      Dir.chdir(tmp_file)
      Bundler::CLI.run(["-m", tmp_file('config', 'manifest.rb').to_s])
      tmp_file("gems").should have_cached_gems("rake-0.8.7")
    end
  end

  describe "it working without rubygems" do
    before(:each) do
      build_manifest <<-Gemfile
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
        gem "extlib"
        gem "rack", :only => :web

        disable_rubygems
      Gemfile

      lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
      bin = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'gem_bundler'))

      Dir.chdir(tmp_dir) do
        @output = `#{Gem.ruby} -I #{lib} #{bin}`
      end
    end

    it "does not load rubygems when required" do
      out = `#{tmp_file('bin', 'rake')} -e 'require "rubygems" ; puts Gem.respond_to?(:sources)'`
      out.should =~ /false/
    end

    it "does not blow up if #gem is used" do
      out = `#{tmp_file('bin', 'rake')} -e 'gem("merb-core") ; puts "Win!"'`
      out.should =~ /Win!/
    end

    it "does not blow up if Gem errors are referred to" do
      out = `#{tmp_file('bin', 'rake')} -e 'Gem::LoadError ; Gem::Exception ; puts "Win!"'`
      out.should =~ /Win!/
    end

    it "stubs out Gem.ruby" do
      out = `#{tmp_file("bin", "rake")} -e 'puts Gem.ruby'`
      out.should == "#{Gem.ruby}\n"
    end
  end

  describe "it working with requiring rubygems automatically" do
    before(:each) do
      build_manifest <<-Gemfile
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
        gem "extlib"
        gem "rack", :only => :web

        require_rubygems
      Gemfile

      lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
      bin = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'gem_bundler'))

      Dir.chdir(tmp_dir) do
        @output = `#{Gem.ruby} -I #{lib} #{bin}`
      end
    end

    it "does already has rubygems required" do
      out = `#{tmp_file('bin', 'rake')} -e 'puts Gem.respond_to?(:sources)'`
      out.should =~ /true/
    end
  end
end
