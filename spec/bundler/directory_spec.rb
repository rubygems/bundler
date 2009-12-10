require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Faking gems with directories" do

  describe "with a simple directory structure" do
    2.times do |i|
      describe "stubbing out a gem with a directory -- #{i}" do
        before(:each) do
          build_lib "very-simple"
          path = tmp_path("libs/very-simple-1.0")
          path = path.relative_path_from(bundled_app) if i == 1

          install_manifest <<-Gemfile
            clear_sources
            source "file://#{gem_repo1}"
            gem "very-simple", "1.0", :path => "#{path}"
          Gemfile
        end

        it "does not download the gem" do
          tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
          tmp_gem_path.should     include_installed_gem("very-simple-1.0")
          tmp_gem_path.should_not include_vendored_dir("very-simple")
        end

        it "has very-simple in the load path" do
          out = run_in_context "require 'very-simple' ; puts VERYSIMPLE"
          out.should == "1.0"
        end

        it "does not remove the directory during cleanup" do
          install_manifest <<-Gemfile
            clear_sources
            source "file://#{gem_repo1}"
          Gemfile

          tmp_path("libs/very-simple-1.0").should be_directory
        end

        it "can bundle --cached" do
          %w(doc gems specifications environment.rb).each do |file|
            FileUtils.rm_rf(tmp_gem_path(file))
          end

          Dir.chdir(bundled_app) do
            out = gem_command :bundle, "--cached"
            out = run_in_context "require 'very-simple' ; puts VERYSIMPLE"
            out.should == "1.0"
          end
        end
      end
    end

    describe "bad directory stubbing" do
      it "raises an exception unless the version is specified" do
        build_lib "very-simple"
        lambda do
          install_manifest <<-Gemfile
            clear_sources
            gem "very-simple", :path => "#{tmp_path}/libs/very-simple-1.0"
          Gemfile
        end.should raise_error(Bundler::DirectorySourceError, /Please explicitly specify a version/)
      end

      it "raises an exception unless the version is an exact version" do
        pending
        lambda do
          install_manifest <<-Gemfile
            clear_sources
            gem "very-simple", ">= 0.1.0", :path => "#{fixture_dir.join("very-simple")}"
          Gemfile
        end.should raise_error(ArgumentError, /:at/)
      end
    end
  end

  it "checks the root directory for a *.gemspec file" do
    build_lib("very-simple", "1.0", :path => tmp_path("very-simple"), :gemspec => true) do |s|
      s.add_dependency "rack", "= 0.9.1"
      s.write "lib/very-simple.rb", "class VerySimpleForTests ; end"
    end

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "very-simple", "1.0", :path => "#{tmp_path("very-simple")}"
    Gemfile

    tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
    tmp_gem_path.should include_cached_gem("rack-0.9.1")
    tmp_gem_path.should include_installed_gem("rack-0.9.1")
  end

  it "works with prerelease gems" do
    build_lib "very-simple", "1.0.pre", :gemspec => true
    install_manifest <<-Gemfile
      clear_sources
      gem "very-simple", :path => "#{tmp_path}/libs/very-simple-1.0.pre"
    Gemfile

    out = run_in_context "Bundler.require_env ; puts VERYSIMPLE"
    out.should == "1.0.pre"
  end

  it "recursively finds all gemspec files in a directory" do
    build_lib("first", "1.0", :gemspec => true)
    build_lib("second", "1.0", :gemspec => true) do |s|
      s.add_dependency "first", ">= 0"
      s.write "lib/second.rb", "require 'first' ; SECOND = '1.0'"
    end

    install_manifest <<-Gemfile
      clear_sources
      gem "second", :path => "#{tmp_path('libs')}"
    Gemfile

    out = run_in_context <<-RUBY
      Bundler.require_env
      puts FIRST
      puts SECOND
    RUBY

    out.should == "1.0\n1.0"
  end

  it "copies bin files to the bin dir" do
    build_lib('very-simple', '1.0', :gemspec => true) do |s|
      s.executables << 'very_simple'
      s.write "bin/very_simple", "#!#{Gem.ruby}\nputs 'OMG'"
    end

    install_manifest <<-Gemfile
      clear_sources
      gem "very-simple", :path => "#{tmp_path('libs/very-simple-1.0')}"
    Gemfile

    tmp_bindir('very_simple').should exist
    `#{tmp_bindir('very_simple')}`.strip.should == 'OMG'
  end

  it "always pulls the dependency from the directory even if there is a newer gem available" do
    build_lib('rack', '0.5', :gemspec => true)

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "rack", :path => "#{tmp_path('libs')}"
    Gemfile

    out = run_in_context <<-RUBY
      Bundler.require_env
      puts RACK
    RUBY

    out.should == '0.5'
  end

  describe "listing gems in a directory" do
    it "directory can take a block" do
      ext = bundled_app("externals")
      ext.mkdir_p

      build_lib "omg",  "1.0", :path => "#{ext}/omg"
      build_lib "hi2u", "1.0", :path => "#{ext}/hi2u"

      install_manifest <<-Gemfile
        clear_sources
        directory "#{ext}" do
          gem "omg",  "1.0", :path => "omg"
          gem "hi2u", "1.0", :path => "hi2u"
        end
      Gemfile

      :default.should have_const("OMG")
      :default.should have_const("HI2U")
    end

    it "directory can specify spermy specifiers" do
      build_lib "omg", "1.0.2", :gemspec => true

      install_manifest <<-Gemfile
        clear_sources
        gem "omg", "~> 1.0.0", :path => "#{tmp_path}/libs"
      Gemfile

      :default.should have_const("OMG")
    end

    it "raises exception when directory does not contain correct gem version" do
      build_lib "omg", "1.0.2", :gemspec => true

      lambda do
        install_manifest <<-Gemfile
          clear_sources
          gem "omg", "~> 1.1", :path => "#{tmp_path}/libs"
        Gemfile
      end.should raise_error(Bundler::GemNotFound, /directory/)
    end

    it "can list vendored gems without :path" do
      build_lib "omg", "1.0"
      install_manifest <<-Gemfile
        clear_sources
        directory "#{tmp_path}/libs/omg-1.0" do
          gem "omg", "1.0"
        end
      Gemfile

      :default.should have_const("OMG")
    end

    it "raises an error when two gems are defined for the same path" do
      build_lib "omg", "1.0"

      lambda {
        install_manifest <<-Gemfile
          clear_sources
          directory "#{tmp_path}/libs/omg-1.0" do
            gem "omg", "1.0", :path => "omg"
            gem "lol", "1.0", :path => "omg"
          end
        Gemfile
      }.should raise_error(Bundler::DirectorySourceError, /already have a gem defined for/)
    end

    it "lets you set a directory source without a block" do
      build_lib "omg", "1.0", :gemspec => true
      build_lib "lol", "1.0", :gemspec => true

      install_manifest <<-Gemfile
        clear_sources
        directory "#{tmp_path}/libs"
        gem "omg"
        gem "lol"
      Gemfile

      :default.should have_const("OMG")
    end
  end

  it "takes a glob" do
    build_lib "omg", "1.0", :gemspec => true
    build_lib "omg", "2.0", :gemspec => true
    install_manifest <<-Gemfile
      clear_sources
      directory "#{tmp_path}/libs", :glob => "**/*-1*/*.gemspec" do
        gem "omg"
      end
    Gemfile

    out = run_in_context "Bundler.require_env ; puts OMG"
    out.should == "1.0"
  end

end