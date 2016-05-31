# frozen_string_literal: true
require "spec_helper"

describe "bundler source plugin" do
  before do
    build_repo2 do
      build_plugin "bundler-source-gitp" do |s|
        s.write "plugin.rb", <<-RUBY
          class SPlugin < Bundler::Plugin::Base
            source :gitp
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
      source "#{lib_path("ga-plugin-1.0")}", :type => :gitp do
        gem "ma-gitp-gem"
      end
    G

    expect(out).to include("Bundle complete!")
  end
end

# Specs to add:
# - Shows error for source with type but without block
