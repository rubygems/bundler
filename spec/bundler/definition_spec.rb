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

        RUBY VERSION
           #{Bundler::RubyVersion.system}

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end

    it "for a path gem with deps and no changes" do
      build_lib "foo", "1.0", :path => lib_path("foo") do |s|
        s.add_dependency "rack", "1.0"
        s.add_development_dependency "net-ssh", "1.0"
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

        RUBY VERSION
           #{Bundler::RubyVersion.system}

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

        RUBY VERSION
           #{Bundler::RubyVersion.system}

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end
  end

  describe "initialize" do
    context "gem version promoter" do
      context "with lockfile" do
        before do
          install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "foo"
          G
        end

        it "should get a locked specs list when updating all" do
          definition = Bundler::Definition.new(bundled_app("Gemfile.lock"), [], Bundler::SourceList.new, true)
          locked_specs = definition.gem_version_promoter.locked_specs
          expect(locked_specs.to_a.map(&:name)).to eq ["foo"]
          expect(definition.instance_variable_get("@locked_specs").empty?).to eq true
        end
      end

      context "without gemfile or lockfile" do
        it "should not attempt to parse empty lockfile contents" do
          definition = Bundler::Definition.new(nil, [], mock_source_list, true)
          expect(definition.gem_version_promoter.locked_specs.to_a).to eq []
        end
      end

      context "shared dependent gems" do
        before do
          build_repo4 do
            build_gem "isolated_owner", %w(1.0.1 1.0.2) do |s|
              s.add_dependency "isolated_dep", "~> 2.0"
            end
            build_gem "isolated_dep", %w(2.0.1 2.0.2)

            build_gem "shared_owner_a", %w(3.0.1 3.0.2) do |s|
              s.add_dependency "shared_dep", "~> 5.0"
            end
            build_gem "shared_owner_b", %w(4.0.1 4.0.2) do |s|
              s.add_dependency "shared_dep", "~> 5.0"
            end
            build_gem "shared_dep", %w(5.0.1 5.0.2)
          end

          gemfile <<-G
            source "file://#{gem_repo4}"
            gem 'isolated_owner'

            gem 'shared_owner_a'
            gem 'shared_owner_b'
          G

          lockfile <<-L
            GEM
              remote: file://#{gem_repo4}
              specs:
                isolated_dep (2.0.1)
                isolated_owner (1.0.1)
                  isolated_dep (~> 2.0)
                shared_dep (5.0.1)
                shared_owner_a (3.0.1)
                  shared_dep (~> 5.0)
                shared_owner_b (4.0.1)
                  shared_dep (~> 5.0)

            PLATFORMS
              ruby

            DEPENDENCIES
              shared_owner_a
              shared_owner_b
              isolated_owner

            BUNDLED WITH
               1.13.0
          L
        end

        it "should unlock isolated and shared dependencies equally" do
          # setup for these test costs about 3/4 of a second, much faster to just jam them all in here.
          # the global before :each defeats any ability to have re-usable setup for many examples in a
          # single context by wiping out the tmp dir and contents.

          unlock_deps_test(%w(isolated_owner), %w(isolated_dep isolated_owner))
          unlock_deps_test(%w(isolated_owner shared_owner_a), %w(isolated_dep isolated_owner shared_dep shared_owner_a))
        end

        def unlock_deps_test(passed_unlocked, expected_calculated)
          definition = Bundler::Definition.new(bundled_app("Gemfile.lock"), [], Bundler::SourceList.new, :gems => passed_unlocked)
          unlock_gems = definition.gem_version_promoter.unlock_gems
          expect(unlock_gems.sort).to eq expected_calculated
        end
      end

      def mock_source_list
        Class.new do
          def all_sources
            []
          end

          def path_sources
            []
          end

          def rubygems_remotes
            []
          end

          def replace_sources!(arg)
            nil
          end
        end.new
      end
    end
  end
end
