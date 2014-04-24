require "spec_helper"

describe "bundle update" do
  describe "svn sources" do
    it "updates correctly when you have like craziness" do
      build_lib "activesupport", "3.0", :path => lib_path("rails/activesupport")
      build_svn "rails", "3.0", :path => lib_path("rails") do |s|
        s.add_dependency "activesupport", "= 3.0"
      end

      install_gemfile <<-G
        gem "rails", :svn => "file://#{lib_path('rails')}"
      G

      bundle "update rails"
      expect(out).to include("Using activesupport 3.0 from file://#{lib_path('rails')} (at HEAD)")
      should_be_installed "rails 3.0", "activesupport 3.0"
    end

    it "floats on master when updating all gems that are pinned to the source even if you have child dependencies" do
      build_svn "foo", :path => lib_path('foo')
      build_gem "bar", :to_system => true do |s|
        s.add_dependency "foo"
      end

      install_gemfile <<-G
        gem "foo", :svn => "file://#{lib_path('foo')}"
        gem "bar"
      G

      update_svn "foo", :path => lib_path('foo') do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update foo"

      should_be_installed "foo 1.1"
    end

    it "notices when you change the repo url in the Gemfile" do
      build_svn "foo", :path => lib_path("foo_one")
      build_svn "foo", :path => lib_path("foo_two")

      install_gemfile <<-G
        gem "foo", "1.0", :svn => "file://#{lib_path('foo_one')}"
      G

      FileUtils.rm_rf lib_path("foo_one")

      install_gemfile <<-G
        gem "foo", "1.0", :svn => "file://#{lib_path('foo_two')}"
      G

      expect(err).to be_empty
      expect(out).to include("Fetching file://#{lib_path}/foo_two")
      expect(out).to include("Your bundle is complete!")
    end

    it "should not explode on invalid revision on update of gem by name" do
      build_svn "rack", "0.8"

      build_svn "rack", "0.8", :path => lib_path('local-rack') do |s|
        s.write "lib/rack.rb", "puts :LOCAL"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}", :branch => "master"
      G

      bundle %|config local.rack #{lib_path('local-rack')}|
      bundle "update rack"
      expect(out).to include("Your bundle is updated!")
    end

    it "shows the previous version of the gem" do
      build_svn "rails", "3.0", :path => lib_path("rails")

      install_gemfile <<-G
        gem "rails", :svn => "file://#{lib_path('rails')}"
      G

      lockfile <<-G
        SVN
          remote: file://#{lib_path("rails")}
          specs:
            rails (2.3.2)

        PLATFORMS
          #{generic(Gem::Platform.local)}

        DEPENDENCIES
          rails!
      G

      bundle "update"
      expect(out).to include("Using rails 3.0 (was 2.3.2) from file://#{lib_path('rails')} (at HEAD)")
    end
  end
end
