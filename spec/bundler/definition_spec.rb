# frozen_string_literal: true
require "spec_helper"
require "bundler/definition"

describe Bundler::Definition do
  describe "#lock" do
    before do
      allow(Bundler).to receive(:settings) { Bundler::Settings.new(".") }
      allow(Bundler).to receive(:default_gemfile) { Pathname.new("Gemfile") }
      allow(Bundler).to receive(:ui) { double("UI", :info => "", :debug => "") }
    end
    context "when it's not possible to write to the file" do
      subject { Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises an PermissionError with explanation" do
        expect(File).to receive(:open).with("Gemfile.lock", "wb").
          and_raise(Errno::EACCES)
        expect { subject.lock("Gemfile.lock") }.
          to raise_error(Bundler::PermissionError, /Gemfile\.lock/)
      end
    end
    context "when a temporary resource access issue occurs" do
      subject { Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises a TemporaryResourceError with explanation" do
        expect(File).to receive(:open).with("Gemfile.lock", "wb").
          and_raise(Errno::EAGAIN)
        expect { subject.lock("Gemfile.lock") }.
          to raise_error(Bundler::TemporaryResourceError, /temporarily unavailable/)
      end
    end
  end

  describe "detects changes" do
    it "for a path gem with changes" do
      build_lib "foo", "1.0", :path => lib_path("foo")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo", :path => "#{lib_path("foo")}"
      G

      build_lib "foo", "1.0", :path => lib_path("foo") do |s|
        s.add_dependency "rack", "1.0"
      end

      bundle :install, :env => { "DEBUG" => 1 }

      expect(out).to match(/re-resolving dependencies/)
      lockfile_should_be <<-G
        PATH
          remote: #{lib_path("foo")}
          specs:
            foo (1.0)
              rack (= 1.0)

        GEM
          remote: file:#{gem_repo1}/
          specs:
            rack (1.0.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          foo!

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end

    it "for a path gem with deps and no changes" do
      build_lib "foo", "1.0", :path => lib_path("foo") do |s|
        s.add_dependency "rack", "1.0"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo", :path => "#{lib_path("foo")}"
      G

      bundle :check, :env => { "DEBUG" => 1 }

      expect(out).to match(/using resolution from the lockfile/)
      lockfile_should_be <<-G
        PATH
          remote: #{lib_path("foo")}
          specs:
            foo (1.0)
              rack (= 1.0)

        GEM
          remote: file:#{gem_repo1}/
          specs:
            rack (1.0.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          foo!

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end

    it "for a rubygems gem" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo"
      G

      bundle :check, :env => { "DEBUG" => 1 }

      expect(out).to match(/using resolution from the lockfile/)
      lockfile_should_be <<-G
        GEM
          remote: file:#{gem_repo1}/
          specs:
            foo (1.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          foo

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end
  end
end
