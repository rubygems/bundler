require "spec_helper"

describe "bundle cache with git" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Git.new("uri" => "git@github.com:bundler.git")
    source.send(:base_name).should == "bundler"
  end

  it "base_name should strip network share paths" do
    source = Bundler::Source::Git.new("uri" => "//MachineName/ShareFolder")
    source.send(:base_name).should == "ShareFolder"
  end

  it "copies repository to vendor cache" do
    git = build_git "foo"
    ref = git.ref_for("master", 11)

    install_gemfile <<-G
      gem "foo", :git => '#{lib_path("foo-1.0")}'
    G

    bundle "cache"
    bundled_app("vendor/cache/foo-1.0-#{ref}").should exist
    bundled_app("vendor/cache/foo-1.0-#{ref}/.git").should_not exist

    FileUtils.rm_rf lib_path("foo-1.0")
    out.should == "Updating .gem files in vendor/cache"
    should_be_installed "foo 1.0"
  end

  it "ignores local repository in favor of the cache" do
    git = build_git "foo"
    ref = git.ref_for("master", 11)

    build_git "foo", :path => lib_path('local-foo') do |s|
      s.write "lib/foo.rb", "raise :FAIL"
    end

    install_gemfile <<-G
      gem "foo", :git => '#{lib_path("foo-1.0")}', :branch => :master
    G

    bundle "cache"
    bundle %|config local.foo #{lib_path('local-foo')}|

    bundle :install
    out.should =~ /at #{bundled_app("vendor/cache/foo-1.0-#{ref}")}/

    should_be_installed "foo 1.0"
  end

  it "copies repository to vendor cache, including submodules" do
    build_git "submodule", "1.0"

    git = build_git "has_submodule", "1.0" do |s|
      s.add_dependency "submodule"
    end

    Dir.chdir(lib_path('has_submodule-1.0')) do
      `git submodule add #{lib_path('submodule-1.0')} submodule-1.0`
      `git commit -m "submodulator"`
    end

    install_gemfile <<-G
      git "#{lib_path('has_submodule-1.0')}", :submodules => true do
        gem "has_submodule"
      end
    G

    ref = git.ref_for("master", 11)
    bundle "cache"

    bundled_app("vendor/cache/has_submodule-1.0-#{ref}").should exist
    bundled_app("vendor/cache/has_submodule-1.0-#{ref}/submodule-1.0").should exist
    out.should == "Updating .gem files in vendor/cache"
    should_be_installed "has_submodule 1.0"
  end
end
