require "spec_helper"

describe "git base name" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Git.new("uri" => "git@github.com:bundler.git")
    source.send(:base_name).should == "bundler"
  end

  it "base_name should strip network share paths" do
    source = Bundler::Source::Git.new("uri" => "//MachineName/ShareFolder")
    source.send(:base_name).should == "ShareFolder"
  end
end

%w(cache package).each do |cmd|
  describe "bundle #{cmd} with git" do
    it "copies repository to vendor cache and uses it" do
      git = build_git "foo"
      ref = git.ref_for("master", 11)

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      bundled_app("vendor/cache/foo-1.0-#{ref}").should exist
      bundled_app("vendor/cache/foo-1.0-#{ref}/.git").should_not exist
      bundled_app("vendor/cache/foo-1.0-#{ref}/.bundlecache").should be_file

      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "copies repository to vendor cache and uses it even when installed with bundle --path" do
      git = build_git "foo"
      ref = git.ref_for("master", 11)

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "install --path vendor/bundle"
      bundle "#{cmd} --all"

      bundled_app("vendor/cache/foo-1.0-#{ref}").should exist
      bundled_app("vendor/cache/foo-1.0-#{ref}/.git").should_not exist

      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "runs twice without exploding" do
      build_git "foo"

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      bundle "#{cmd} --all"

      err.should == ""
      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "tracks updates" do
      git = build_git "foo"
      old_ref = git.ref_for("master", 11)

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"

      update_git "foo" do |s|
        s.write "lib/foo.rb", "puts :CACHE"
      end

      ref = git.ref_for("master", 11)
      ref.should_not == old_ref

      bundle "update"
      bundle "#{cmd} --all"

      bundled_app("vendor/cache/foo-1.0-#{ref}").should exist
      bundled_app("vendor/cache/foo-1.0-#{old_ref}").should_not exist

      FileUtils.rm_rf lib_path("foo-1.0")
      run "require 'foo'"
      out.should == "CACHE"
    end

    it "uses the local repository to generate the cache" do
      git = build_git "foo"
      ref = git.ref_for("master", 11)

      gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-invalid")}', :branch => :master
      G

      bundle %|config local.foo #{lib_path('foo-1.0')}|
      bundle "install"
      bundle "#{cmd} --all"

      bundled_app("vendor/cache/foo-invalid-#{ref}").should exist

      # Updating the local still uses the local.
      update_git "foo" do |s|
        s.write "lib/foo.rb", "puts :LOCAL"
      end

      run "require 'foo'"
      out.should == "LOCAL"
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
      bundle "#{cmd} --all"

      bundled_app("vendor/cache/has_submodule-1.0-#{ref}").should exist
      bundled_app("vendor/cache/has_submodule-1.0-#{ref}/submodule-1.0").should exist
      should_be_installed "has_submodule 1.0"
    end

    it "displays warning message when detecting git repo in Gemfile" do
      git = build_git "foo"
      ref = git.ref_for("master", 11)

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd}"

      out.should include("Your Gemfile contains path and git dependencies.")
    end

    it "does not display warning message if cache_all is set in bundle config" do
      git = build_git "foo"
      ref = git.ref_for("master", 11)

      install_gemfile <<-G
        gem "foo", :git => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      bundle "#{cmd}"

      out.should_not include("Your Gemfile contains path and git dependencies.")
    end
  end
end