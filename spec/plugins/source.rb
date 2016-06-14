# frozen_string_literal: true
require "spec_helper"

describe "bundler source plugin" do
  before do
    build_repo2 do
      build_plugin "bundler-source-gitp" do |s|
        s.write "plugins.rb", <<-RUBY
          class SPlugin < Bundler::Plugin::API
            source "gitp"

            def initialize(opts)
              super

              @ref = options["ref"] || options["branch"] || options["tag"] || "master"
            end

            def fetch_gemfiles
              @glob = "{,*,*/*}.gemspec"
              @bare_loc = tmp('splugin')
              `git clone \#{@options["uri"]} \#{@bare_loc}`

              Dir["\#{@bare_loc}/\#{@glob}"].sort_by {|p| -p.split(File::SEPARATOR).size }
            end

            def install(spec, opts)
              mkdir_p(install_path.dirname)
              rm_rf(install_path)
              `git clone --no-checkout --quiet "\#{@bare_loc}" "\#{install_path}"`
              Dir.chdir install_path do
                `git reset --hard \#{revision}`
              end
            end

            def revision
              Dir.chdir @bare_loc do
                `git rev-parse --verify \#{@ref}`.strip
              end
            end

            def base_name
              File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)?(//\w*/)?(\w*/)*}, ""), ".git")
            end

            def shortref_for_display(ref)
              ref[0..6]
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
          end
        RUBY
      end
    end
  end

  it "installs source automatically from #source :type option" do
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      source "file://#{lib_path("gitp")}", :type => :gitp do
      end
    G

    expect(out).to include("Installed plugin bundler-source-gitp")

    expect(out).to include("Bundle complete!")
  end

  it "handles the source option", :focused do
    build_git "ma-gitp-gem"
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      source "#{lib_path("ma-gitp-gem-1.0")}", :type => :gitp do
        gem "ma-gitp-gem"
      end
      #gem 'ma-gitp-gem', :git => "#{lib_path("ma-gitp-gem-1.0")}"
    G

    expect(out).to include("Bundle complete!")
    should_be_installed("ma-gitp-gem 1.0")
  end
end

# Specs to add:
# - Shows error for source with type but without block
