# frozen_string_literal: true
require "spec_helper"

describe "bundler source plugin" do
  it "installs source automatically from #source :type option" do
    update_repo2 do
      build_plugin "bundler-source-psource" do |s|
        s.write "plugins.rb", <<-RUBY
            class Cheater < Bundler::Plugin::API
              source "psource", self
            end
        RUBY
      end
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      source "file://#{lib_path("gitp")}", :type => :psource do
      end
    G

    expect(out).to include("Installed plugin bundler-source-psource")

    expect(out).to include("Bundle complete!")
  end

  context "with a real source plugin" do
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
                  if installed?
                    path = install_path
                  else
                    path = cache_path
                  end
                  Dir["\#{path}/\#{glob}"].sort_by {|p| -p.split(File::SEPARATOR).size }
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
                {"revision" => revision}
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
                @revision ||= locked_revision || begin
                  Dir.chdir cache_path do
                    `git rev-parse --verify \#{@ref}`.strip
                  end
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
        end # build_plugin
      end # build_repo

      build_git "ma-gitp-gem"

      gemfile <<-G
        source "file://#{gem_repo2}" # plugin source
        source "file://#{lib_path("ma-gitp-gem-1.0")}", :type => :gitp do
          gem "ma-gitp-gem"
        end
        #gem 'ma-gitp-gem', :git => "file://#{lib_path("ma-gitp-gem-1.0")}"
      G
    end # before

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
    end
  end
end

# Specs to add:
# - Shows error for source with type but without block
