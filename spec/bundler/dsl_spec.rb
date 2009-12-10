require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler DSL" do

  it "supports only blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"

      gem "activerecord"

      only :test do
        gem "rspec", :require_as => "spec"
        gem "very-simple"
      end
    Gemfile

    "default".should have_const("ACTIVERECORD")
    "default".should_not have_const("SPEC")
    "default".should_not have_const("VERYSIMPLE")

    "test".should have_const("ACTIVERECORD")
    "test".should have_const("SPEC")
    "test".should have_const("VERYSIMPLE")
  end

  it "supports only blocks with multiple args" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      only :test, :production do
        gem "rack"
      end
    Gemfile

    "default".should_not have_const("RACK")
    "test".should have_const("RACK")
    "production".should have_const("RACK")
  end

  it "supports nesting only blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"

      only [:test, :staging] do
        gem "very-simple"
        only :test do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "test".should have_const("VERYSIMPLE")
    "test".should have_const("SPEC")
    "staging".should have_const("VERYSIMPLE")
    "staging".should_not have_const("SPEC")
  end

  it "supports except blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"

      gem "activerecord"

      except :test do
        gem "rspec", :require_as => "spec"
        gem "very-simple"
      end
    Gemfile

    "default".should have_const("ACTIVERECORD")
    "default".should have_const("SPEC")
    "default".should have_const("VERYSIMPLE")

    "test".should have_const("ACTIVERECORD")
    "test".should_not have_const("SPEC")
    "test".should_not have_const("VERYSIMPLE")
  end

  it "supports except blocks with multiple args" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      except :test, :production do
        gem "rack"
      end
    Gemfile

    "default".should have_const("RACK")
    "test".should_not have_const("RACK")
    "production".should_not have_const("RACK")
  end

  it "supports nesting except blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"

      except [:test] do
        gem "very-simple"
        except :omg do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "default".should have_const("SPEC")
    "default".should have_const("VERYSIMPLE")
    "test".should_not have_const("VERYSIMPLE")
    "test".should_not have_const("SPEC")
    "omg".should have_const("VERYSIMPLE")
    "omg".should_not have_const("SPEC")
  end

  it "raises an exception if you provide an invalid key" do
    lambda do
      install_manifest <<-Gemfile
        clear_sources

        gem "very-simple", :version => "1.0"
      Gemfile
    end.should raise_error(Bundler::InvalidKey)
  end
end