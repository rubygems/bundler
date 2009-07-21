require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::CLI" do

  describe "helper methods" do
    before(:each) do
      @original_pwd = Dir.pwd
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      @cli = Bundler::CLI
    end

    after(:each) do
      Dir.chdir(@original_pwd)
    end

    it "finds the default manifest file" do
      Dir.chdir(tmp_dir)
      FileUtils.touch(tmp_file("Gemfile"))
      @cli.default_manifest.should == tmp_file("Gemfile").to_s
    end

    it "finds the default manifest file when it's in a parent directory" do
      FileUtils.mkdir_p(tmp_file("wot"))
      FileUtils.touch(tmp_file("Gemfile"))
      Dir.chdir(tmp_file("wot"))
      @cli.default_manifest.should == tmp_file("Gemfile").to_s
    end

    it "sets the default bundle path to vendor/gems" do
      Dir.chdir(tmp_dir)
      FileUtils.touch(tmp_file("Gemfile"))
      @cli.default_path.should == tmp_file("vendor", "gems").to_s
    end

    it "sets the default bundle path relative to the Gemfile" do
      FileUtils.mkdir_p(tmp_file("wot"))
      FileUtils.touch(tmp_file("Gemfile"))
      Dir.chdir(tmp_file("wot"))
      @cli.default_path.should == tmp_file("vendor", "gems").to_s
    end

    it "sets the default bindir relative to the Gemfile" do
      FileUtils.mkdir_p(tmp_file("wot"))
      FileUtils.touch(tmp_file("Gemfile"))
      Dir.chdir(tmp_file("wot"))
      @cli.default_bindir.should == tmp_file("bin").to_s
    end
  end

  describe "it working" do
    before(:all) do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)

      File.open(tmp_file("Gemfile"), 'w') do |file|
        file.puts <<-DSL
          sources.clear
          source "file://#{gem_repo1}"
          gem "rake"
          gem "extlib"
          gem "rack", :only => :web
        DSL
      end

      lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
      bin = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'gem_bundler'))

      Dir.chdir(tmp_dir) do
        @output = `#{Gem.ruby} -I #{lib} #{bin}`
      end
    end

    before(:each) do
      @original_pwd = Dir.pwd
    end

    after(:each) do
      Dir.chdir(@original_pwd)
    end

    it "caches and installs rake" do
      gems = %w(rake-0.8.7 extlib-0.9.12 rack-0.9.1)
      tmp_file("vendor", "gems").should have_cached_gems(*gems)
      tmp_file("vendor", "gems").should have_installed_gems(*gems)
    end

    it "creates a default environment file with the appropriate load paths" do
      tmp_file('vendor', 'gems', 'environments', 'default.rb').should have_load_paths(tmp_file("vendor", "gems"),
        "extlib-0.9.12" => %w(lib),
        "rake-0.8.7" => %w(bin lib)
      )

      tmp_file('vendor', 'gems', 'environments', 'web.rb').should have_load_paths(tmp_file("vendor", "gems"),
        "extlib-0.9.12" => %w(lib),
        "rake-0.8.7" => %w(bin lib),
        "rack-0.9.1" => %w(bin lib)
      )
    end

    it "creates an executable for rake in ./bin" do
      out = `#{tmp_file('bin', 'rake')} -e 'puts $:'`
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "lib").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "rake-0.8.7", "bin").to_s)
      out.should include(tmp_file("vendor", "gems", "gems", "extlib-0.9.12", "lib").to_s)
      out.should_not include(tmp_file("vendor", "gems", "gems", "rack-0.9.1").to_s)
    end

    it "logs the correct information messages" do
      [ "Updating source: file:#{gem_repo1}",
        "Calculating dependencies...",
        "Downloading rake-0.8.7.gem",
        "Downloading extlib-0.9.12.gem",
        "Downloading rack-0.9.1.gem",
        "Installing rake-0.8.7.gem",
        "Installing extlib-0.9.12.gem",
        "Installing rack-0.9.1.gem",
        "Done." ].each do |message|
          @output.should =~ /^#{Regexp.escape(message)}$/
        end
    end
  end
end