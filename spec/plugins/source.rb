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
  end
end

# Specs to add:
# - Shows error for source with type but without block
