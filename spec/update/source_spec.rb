require "spec_helper"

describe "bundle update" do
  describe "git sources" do
    before :each do
      @git = build_git "foo", :path => lib_path("foo") do |s|
        s.executables = "foobar"
      end

      install_gemfile <<-G
        git "#{lib_path('foo')}"
        gem 'foo'
      G
    end

    it "updates the source" do
      update_git "foo", :path => @git.path

      bundle "update --source foo"

      in_app_root do
        run <<-RUBY
          require 'foo'
          puts "WIN" if defined?(FOO_PREV_REF)
        RUBY

        out.should == "WIN"
      end
    end
  end
end