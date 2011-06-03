require "spec_helper"

describe "bundle update" do
  describe "hg sources" do
    it "floats on a branch when :branch is used" do
      build_hg  "foo", "1.0"
      update_hg "foo", :branch => "omg"

      install_gemfile <<-G
        hg "#{lib_path('foo-1.0')}", :branch => "omg" do
          gem 'foo'
        end
      G

      update_hg "foo", :branch => "omg" do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update"

      should_be_installed "foo 1.1"
    end

    it "updates correctly when you have like craziness" do
      build_lib "activesupport", "3.0", :path => lib_path("rails/activesupport")
      build_hg "rails", "3.0", :path => lib_path("rails") do |s|
        s.add_dependency "activesupport", "= 3.0"
      end

      install_gemfile <<-G
        gem "rails", :hg => "#{lib_path('rails')}"
      G

      bundle "update rails"
      out.should include("Using activesupport (3.0) from #{lib_path('rails')} (at default)")
      should_be_installed "rails 3.0", "activesupport 3.0"
    end

    it "floats on a branch when :branch is used and the source is specified in the update" do
      build_hg  "foo", "1.0", :path => lib_path("foo")
      update_hg "foo", :branch => "omg", :path => lib_path("foo")

      install_gemfile <<-G
        hg "#{lib_path('foo')}", :branch => "omg" do
          gem 'foo'
        end
      G

      update_hg "foo", :branch => "omg", :path => lib_path("foo") do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update --source foo"

      should_be_installed "foo 1.1"
    end

    it "floats on master when updating all gems that are pinned to the source even if you have child dependencies" do
      build_hg "foo", :path => lib_path('foo')
      build_gem "bar", :to_system => true do |s|
        s.add_dependency "foo"
      end

      install_gemfile <<-G
        gem "foo", :hg => "#{lib_path('foo')}"
        gem "bar"
      G

      update_hg "foo", :path => lib_path('foo') do |s|
        s.write "lib/foo.rb", "FOO = '1.1'"
      end

      bundle "update foo"

      should_be_installed "foo 1.1"
    end

    it "notices when you change the repo url in the Gemfile" do
      build_hg "foo", :path => lib_path("foo_one")
      build_hg "foo", :path => lib_path("foo_two")

      install_gemfile <<-G
        gem "foo", "1.0", :hg => "#{lib_path('foo_one')}"
      G

      FileUtils.rm_rf lib_path("foo_one")

      install_gemfile <<-G
        gem "foo", "1.0", :hg => "#{lib_path('foo_two')}"
      G

      err.should be_empty
      out.should include("Fetching #{lib_path}/foo_two")
      out.should include("Your bundle is complete!")
    end


    it "fetches tags from the remote" do
      build_hg "foo"
      @remote = build_hg("bar", :bare => true)
      update_hg "foo", :remote => @remote.path
      update_hg "foo", :push => "default"

      install_gemfile <<-G
        gem 'foo', :hg => "#{@remote.path}"
      G

      # Create a new tag on the remote that needs fetching
      update_hg "foo", :tag => "fubar"
      update_hg "foo", :push => "fubar"

      gemfile <<-G
        gem 'foo', :hg => "#{@remote.path}", :tag => "fubar"
      G

      bundle "update", :exitstatus => true
      exitstatus.should == 0
    end

    it "errors with a message when the .hg repo is gone" do
      build_hg "foo", "1.0"

      install_gemfile <<-G
        gem "foo", :hg => "#{lib_path('foo-1.0')}"
      G

      lib_path("foo-1.0").join(".hg").rmtree

      bundle :update, :expect_err => true
      out.should include(lib_path("foo-1.0").to_s)
    end

  end
end
