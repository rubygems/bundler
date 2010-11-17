require "spec_helper"

describe "bundle install --standalone" do
  describe "with simple gems" do
    before do
      install_gemfile <<-G, :standalone => true
        source "file://#{gem_repo1}"
        gem "rails"
      G
    end

    it "still makes the gems available to normal bundler" do
      should_be_installed "actionpack 2.3.2", "rails 2.3.2"
    end

    it "generates a bundle/bundler/setup.rb" do
      bundled_app("bundle/bundler/setup.rb").should exist
    end

    it "makes the gems available without bundler" do
      ruby <<-RUBY, :no_lib => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        puts ACTIONPACK
      RUBY

      out.should == "2.3.2"
    end

    it "works on a different system" do
      FileUtils.mv(bundled_app, "#{bundled_app}2")
      Dir.chdir("#{bundled_app}2")

      ruby <<-RUBY, :no_lib => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        puts ACTIONPACK
      RUBY

      out.should == "2.3.2"
    end
  end

  describe "with a combination of gems and git repos" do
    before do
      build_git "devise", "1.0"

      install_gemfile <<-G, :standalone => true
        source "file://#{gem_repo1}"
        gem "rails"
        gem "devise", :git => "#{lib_path('devise-1.0')}"
      G
    end

    it "still makes the gems available to normal bundler" do
      should_be_installed "actionpack 2.3.2", "rails 2.3.2", "devise 1.0"
    end

    it "generates a bundle/bundler/setup.rb" do
      bundled_app("bundle/bundler/setup.rb").should exist
    end

    it "makes the gems available without bundler" do
      ruby <<-RUBY, :no_lib => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "devise"
        require "actionpack"
        puts DEVISE
        puts ACTIONPACK
      RUBY

      out.should == "1.0\n2.3.2"
    end
  end

  describe "with groups" do
    before do
      build_git "devise", "1.0"

      install_gemfile <<-G, :standalone => true
        source "file://#{gem_repo1}"
        gem "rails"

        group :test do
          gem "rspec"
          gem "rack-test"
        end
      G
    end

    it "makes the gems available without bundler" do
      ruby <<-RUBY, :no_lib => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        require "spec"
        require "rack/test"
        puts ACTIONPACK
        puts SPEC
        puts RACK_TEST
      RUBY

      out.should == "2.3.2\n1.2.7\n1.0"
    end

    it "allows creating a standalone file with limited groups" do
      bundle "install --standalone default"

      ruby <<-RUBY, :no_lib => true, :expect_err => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        puts ACTIONPACK
        require "spec"
      RUBY

      out.should == "2.3.2"
      err.should =~ /no such file to load.*spec/
    end

    it "allows --without to limit the groups used in a standalone" do
      bundle "install --standalone --without test"

      ruby <<-RUBY, :no_lib => true, :expect_err => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        puts ACTIONPACK
        require "spec"
      RUBY

      out.should == "2.3.2"
      err.should =~ /no such file to load.*spec/
    end

    it "allows remembered --without to limit the groups used in a standalone" do
      bundle "install --without test"
      bundle "install --standalone"

      ruby <<-RUBY, :no_lib => true, :expect_err => true
        $:.unshift File.expand_path("bundle")
        require "bundler/setup"

        require "actionpack"
        puts ACTIONPACK
        require "spec"
      RUBY

      out.should == "2.3.2"
      err.should =~ /no such file to load.*spec/
    end
  end
end
