require "spec_helper"

%w(cache package).each do |cmd|
  describe "bundle #{cmd} with svn" do
    it "copies repository to vendor cache and uses it" do
      svn = build_svn "foo"
      ref = svn.ref_for("HEAD")

      install_gemfile <<-G
        gem "foo", :svn => 'file://#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      expect(bundled_app("vendor/cache/foo-1.0-#{ref}")).to exist
      expect(bundled_app("vendor/cache/foo-1.0-#{ref}/.svn")).to exist

      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "copies repository to vendor cache and uses it even when installed with bundle --path" do
      svn = build_svn "foo"
      ref = svn.ref_for("HEAD")

      install_gemfile <<-G
        gem "foo", :svn => 'file://#{lib_path("foo-1.0")}'
      G

      bundle "install --path vendor/bundle"
      bundle "#{cmd} --all"

      expect(bundled_app("vendor/cache/foo-1.0-#{ref}")).to exist
      expect(bundled_app("vendor/cache/foo-1.0-#{ref}/.svn")).to exist

      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "runs twice without exploding" do
      build_svn "foo"

      install_gemfile <<-G
        gem "foo", :svn => 'file://#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      bundle "#{cmd} --all"

      expect(err).to eq("")
      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "tracks updates" do
      svn = build_svn "foo"
      old_ref = svn.ref_for("HEAD")

      install_gemfile <<-G
        gem "foo", :svn => 'file://#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"

      update_svn "foo" do |s|
        s.write "lib/foo.rb", "puts :CACHE"
      end

      ref = svn.ref_for("HEAD")
      expect(ref).not_to eq(old_ref)

      bundle "update"
      bundle "#{cmd} --all"

      expect(bundled_app("vendor/cache/foo-1.0-#{ref}")).to exist

      FileUtils.rm_rf lib_path("foo-1.0")
      run "require 'foo'"
      expect(out).to eq("CACHE")
    end

  end
end
