require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::CLI" do

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

  it "works" do
    File.open(tmp_file("Gemfile"), 'w') do |file|
      file.puts <<-DSL
        sources.clear
        source "file://#{gem_repo1}"
        gem "rake"
      DSL
    end

    lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
    bin = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin', 'gem_bundler'))

    Dir.chdir(tmp_dir) do
      `#{Gem.ruby} -I #{lib} #{bin}`
    end

    tmp_file("vendor", "gems").should have_cached_gems("rake-0.8.7")
    tmp_file("vendor", "gems").should have_installed_gems("rake-0.8.7")

    tmp_file('vendor', 'gems', 'environments', 'default.rb').should have_load_paths(tmp_file("vendor", "gems"),
      "rake-0.8.7" => %w(bin lib)
    )
  end

end