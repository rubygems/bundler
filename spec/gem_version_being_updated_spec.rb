require "spec_helper"

describe "bundle update" do

  it "shows the old version of the gem being updated from rubygems" do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
    G

    bundle "update"
    expect(out).to include("Using activesupport (2.3.5)")
  end

  it "updates to activesupport 3.0" do
    update_repo2 do
      build_gem "activesupport", "3.0"
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
    G

    bundle "update"
    expect(out).to include("Using activesupport (3.0) was (2.3.5)")
  end

  it "shows the old version of the gem being updated from git" do
    build_git "rails", "3.0", :path => lib_path("rails")

    install_gemfile <<-G
      gem "rails", :git => "#{lib_path('rails')}"
    G

    bundle "update"
    expect(out).to include("Using rails (3.0) from #{lib_path('rails')} (at master)")

  end

  it "shows the old version of the gem being updated from path" do
    build_lib "activesupport", "3.0", :path => lib_path("rails/activesupport")

    install_gemfile <<-G
      gem "activesupport", :path => "#{lib_path('rails/activesupport')}"
    G

    bundle "update"
    expect(out).to include("Using activesupport (3.0) from source at #{lib_path('rails/activesupport')}")
  end
end