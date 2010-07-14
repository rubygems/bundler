require "spec_helper"

describe "bundle cache with multiple platforms" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :ruby do
        gem "rack", "1.0.0"
      end

      platforms :jruby do
        gem "activesupport", "2.3.5"
      end
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          activesupport (2.3.5)

      PLATFORMS
        ruby
        java

      DEPENDENCIES
        rack (1.0.0)
        activesupport (2.3.5)
    G
  end

  it "does not delete gems for other platforms" do
    cache_gems "rack-1.0.0", "activesupport-2.3.5"
    bundle "install"

    bundled_app("vendor/cache/rack-1.0.0.gem").should exist
    bundled_app("vendor/cache/activesupport-2.3.5.gem").should exist
  end
end
