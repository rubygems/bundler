require "spec_helper"

describe "bundle update" do
  describe "git sources" do
    it "floats on a branch when :branch is used" do
      build_git  "foo", "1.0"
      update_git "foo", :branch => "omg"

      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}", :branch => "omg" do
          gem 'foo'
        end
      G

      update_git "foo", :branch => "omg" do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update"

      should_be_installed "foo 1.1"
    end

    it "updates correctly when you have like craziness" do
      build_lib "activesupport", "3.0", :path => lib_path("rails/activesupport")
      build_git "rails", "3.0", :path => lib_path("rails") do |s|
        s.add_dependency "activesupport", "= 3.0"
      end

      install_gemfile <<-G
        gem "rails", :git => "#{lib_path('rails')}"
      G

      bundle "update rails"
      out.should include("Using activesupport (3.0) from #{lib_path('rails')} (at master)")
      should_be_installed "rails 3.0", "activesupport 3.0"
    end
    it "floats on a branch when :branch is used and the source is specified in the update" do
      build_git  "foo", "1.0", :path => lib_path("foo")
      update_git "foo", :branch => "omg", :path => lib_path("foo")

      install_gemfile <<-G
        git "#{lib_path('foo')}", :branch => "omg" do
          gem 'foo'
        end
      G

      update_git "foo", :branch => "omg", :path => lib_path("foo") do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update --source foo"

      should_be_installed "foo 1.1"
    end

    it "notices when you change the repo url in the Gemfile" do
      build_git "foo", :path => lib_path("foo_one")
      build_git "foo", :path => lib_path("foo_two")

      install_gemfile <<-G
        gem "foo", "1.0", :git => "#{lib_path('foo_one')}"
      G

      FileUtils.rm_rf lib_path("foo_one")

      install_gemfile <<-G
        gem "foo", "1.0", :git => "#{lib_path('foo_two')}"
      G

      err.should be_empty
      out.should include("Fetching #{lib_path}/foo_two")
      out.should include("Your bundle is complete!")
    end
  end
end
