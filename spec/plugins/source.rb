# frozen_string_literal: true
require "spec_helper"

describe "bundler source plugin" do
  describe "plugins dsl eval for #source with :type option" do
    before do
      update_repo2 do
        build_plugin "bundler-source-psource" do |s|
          s.write "plugins.rb", <<-RUBY
              class OPSource < Bundler::Plugin::API
                source "psource"
              end
          RUBY
        end
      end
    end

    it "installs bundler-source-* gem when no handler for source is present" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        source "file://#{lib_path("gitp")}", :type => :psource do
        end
      G

      plugin_should_be_installed("bundler-source-psource")
    end

    it "does nothing when a handler is already installed" do
      update_repo2 do
        build_plugin "another-psource" do |s|
          s.write "plugins.rb", <<-RUBY
              class Cheater < Bundler::Plugin::API
                source "psource"
              end
          RUBY
        end
      end

      bundle "plugin install another-psource --source file://#{gem_repo2}"

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        source "file://#{lib_path("gitp")}", :type => :psource do
        end
      G

      plugin_should_not_be_installed("bundler-source-psource")
    end
  end

  context "with a minimal source plugin" do
    before do
      build_repo2 do
        build_plugin "bundler-source-mpath" do |s|
          s.write "plugins.rb", <<-RUBY
            require "fileutils"

            class MPath < Bundler::Plugin::API
              source "mpath"

              attr_reader :path

              def initialize(opts)
                super

                @path = Pathname.new options["uri"]
              end

              def fetch_gemfiles
                @gemfiles ||= begin
                  glob = "{,*,*/*}.gemspec"
                  if installed?
                    search_path = install_path
                  else
                    search_path = path
                  end
                  Dir["\#{search_path.to_s}/\#{glob}"]
                end
              end

              def install(spec, opts)
                mkdir_p(install_path.parent)
                FileUtils.cp_r(path, install_path)

                nil
              end
            end
          RUBY
        end # build_plugin
      end

      build_lib "a-path-gem"

      gemfile <<-G
        source "file://#{gem_repo2}" # plugin source
        source "#{lib_path("a-path-gem-1.0")}", :type => :mpath do
          gem "a-path-gem"
        end
      G
    end

    it "installs" do
      bundle "install"

      should_be_installed("a-path-gem 1.0")
    end

    it "writes to lock file" do
      bundle "install"

      lockfile_should_be <<-G
        PLUGIN
          remote: #{lib_path("a-path-gem-1.0")}
          type: mpath
          specs:
            a-path-gem (1.0)

        GEM
          remote: file:#{gem_repo2}/
          specs:

        PLATFORMS
          #{generic_local_platform}

        DEPENDENCIES
          a-path-gem!

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end

    context "with lockfile" do
      before do
        lockfile <<-G
          PLUGIN
            remote: #{lib_path("a-path-gem-1.0")}
            type: mpath
            specs:
              a-path-gem (1.0)

          GEM
            remote: file:#{gem_repo2}/
            specs:

          PLATFORMS
            #{generic_local_platform}

          DEPENDENCIES
            a-path-gem!

          BUNDLED WITH
             #{Bundler::VERSION}
        G
      end

      it "installs" do
        bundle "install"

        should_be_installed("a-path-gem 1.0")
      end
    end
  end

  context "with a more elaborate source plugin" do
    before do
      build_repo2 do
        build_plugin "bundler-source-gitp" do |s|
          s.write "plugins.rb", <<-RUBY
            class SPlugin < Bundler::Plugin::API
              source "gitp"

              attr_reader :ref

              def initialize(opts)
                super

                @ref = options["ref"] || options["branch"] || options["tag"] || "master"
                @unlocked = false
              end

              def eql?(other)
                other.is_a?(self.class) && uri == other.uri && ref == other.ref
              end

              alias_method :==, :eql?

              def fetch_gemfiles
                @gemfiles ||= begin
                  glob = "{,*,*/*}.gemspec"
                  if !cached?
                    cache_repo
                  end

                  if installed? && !@unlocked
                    path = install_path
                  else
                    path = cache_path
                  end

                  Dir["\#{path}/\#{glob}"]
                end
              end

              def install(spec, opts)
                mkdir_p(install_path.dirname)
                rm_rf(install_path)
                `git clone --no-checkout --quiet "\#{cache_path}" "\#{install_path}"`
                Dir.chdir install_path do
                  `git reset --hard \#{revision}`
                end

                nil
              end

              def options_to_lock
                opts = {"revision" => revision}
                opts["ref"] = ref if ref != "master"
                opts
              end

              def unlock!
                @unlocked = true
                @revision = latest_revision
              end

            private

              def cache_path
                @cache_path ||= cache.join("gitp", base_name)
              end

              def cache_repo
                `git clone --quiet \#{@options["uri"]} \#{cache_path}`
              end

              def cached?
                File.directory?(cache_path)
              end

              def locked_revision
                options["revision"]
              end

              def revision
                @revision ||= locked_revision || latest_revision
              end

              def latest_revision
                if !cached? || @unlocked
                  rm_rf(cache_path)
                  cache_repo
                end

                Dir.chdir cache_path do
                  `git rev-parse --verify \#{@ref}`.strip
                end
              end

              def base_name
                File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)?(//\w*/)?(\w*/)*}, ""), ".git")
              end

              def shortref_for_path(ref)
                ref[0..12]
              end

              def install_path
                @install_path ||= begin
                  git_scope = "\#{base_name}-\#{shortref_for_path(revision)}"

                  path = super.join(git_scope)

                  if !path.exist? && requires_sudo?
                    user_bundle_path.join(ruby_scope).join(git_scope)
                  else
                    path
                  end
                end
              end

              def installed?
                File.directory?(install_path)
              end
            end
          RUBY
        end
      end

      build_git "ma-gitp-gem"

      gemfile <<-G
        source "file://#{gem_repo2}" # plugin source
        source "file://#{lib_path("ma-gitp-gem-1.0")}", :type => :gitp do
          gem "ma-gitp-gem"
        end
      G
    end

    it "handles the source option" do
      bundle "install"
      expect(out).to include("Bundle complete!")
      should_be_installed("ma-gitp-gem 1.0")
    end

    it "writes to lock file" do
      revision = revision_for(lib_path("ma-gitp-gem-1.0"))
      bundle "install"

      lockfile_should_be <<-G
        PLUGIN
          remote: file://#{lib_path("ma-gitp-gem-1.0")}
          type: gitp
          revision: #{revision}
          specs:
            ma-gitp-gem (1.0)

        GEM
          remote: file:#{gem_repo2}/
          specs:

        PLATFORMS
          #{generic_local_platform}

        DEPENDENCIES
          ma-gitp-gem!

        BUNDLED WITH
           #{Bundler::VERSION}
      G
    end

    context "with lockfile" do
      before do
        revision = revision_for(lib_path("ma-gitp-gem-1.0"))
        lockfile <<-G
          PLUGIN
            remote: file://#{lib_path("ma-gitp-gem-1.0")}
            type: gitp
            revision: #{revision}
            specs:
              ma-gitp-gem (1.0)

          GEM
            remote: file:#{gem_repo2}/
            specs:

          PLATFORMS
            #{generic_local_platform}

          DEPENDENCIES
            ma-gitp-gem!

          BUNDLED WITH
             #{Bundler::VERSION}
        G
      end

      it "installs" do
        bundle "install"
        should_be_installed("ma-gitp-gem 1.0")
      end

      it "uses the locked ref" do
        update_git "ma-gitp-gem"
        bundle "install"

        run <<-RUBY
          require 'ma-gitp-gem'
          puts "WIN" unless defined?(MAGITPGEM_PREV_REF)
        RUBY
        expect(out).to eq("WIN")
      end

      it "updates the deps on bundler update" do
        update_git "ma-gitp-gem"
        bundle "update ma-gitp-gem"

        run <<-RUBY
          require 'ma-gitp-gem'
          puts "WIN" if defined?(MAGITPGEM_PREV_REF)
        RUBY
        expect(out).to eq("WIN")
      end

      it "updates the deps on change in gemfile" do
        update_git "ma-gitp-gem", "1.1", :path => lib_path("ma-gitp-gem-1.0"), :gemspec => true
        gemfile <<-G
          source "file://#{gem_repo2}" # plugin source
          source "file://#{lib_path("ma-gitp-gem-1.0")}", :type => :gitp do
            gem "ma-gitp-gem", "1.1"
          end
        G
        bundle "install"

        should_be_installed("ma-gitp-gem 1.1")
      end
    end
  end
end
