require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler DSL" do

  it "supports only blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"

      gem "activerecord"

      only :test do
        gem "rspec", :require_as => "spec"
        gem "very-simple"
      end
    Gemfile

    "default".should have_const("ActiveRecord")
    "default".should_not have_const("Spec")
    "default".should_not have_const("VerySimpleForTests")

    "test".should have_const("ActiveRecord")
    "test".should have_const("Spec")
    "test".should have_const("VerySimpleForTests")
  end

  it "supports only blocks with multiple args" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      only :test, :production do
        gem "rack"
      end
    Gemfile

    "default".should_not have_const("Rack")
    "test".should have_const("Rack")
    "production".should have_const("Rack")
  end

  it "supports nesting only blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"

      only [:test, :staging] do
        gem "very-simple"
        only :test do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "test".should have_const("VerySimpleForTests")
    "test".should have_const("Spec")
    "staging".should have_const("VerySimpleForTests")
    "staging".should_not have_const("Spec")
  end

  it "supports except blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"

      gem "activerecord"

      except :test do
        gem "rspec", :require_as => "spec"
        gem "very-simple"
      end
    Gemfile

    "default".should have_const("ActiveRecord")
    "default".should have_const("Spec")
    "default".should have_const("VerySimpleForTests")

    "test".should have_const("ActiveRecord")
    "test".should_not have_const("Spec")
    "test".should_not have_const("VerySimpleForTests")
  end

  it "supports except blocks with multiple args" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      except :test, :production do
        gem "rack"
      end
    Gemfile

    "default".should have_const("Rack")
    "test".should_not have_const("Rack")
    "production".should_not have_const("Rack")
  end

  it "supports nesting except blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"

      except [:test] do
        gem "very-simple"
        except :omg do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "default".should have_const("Spec")
    "default".should have_const("VerySimpleForTests")
    "test".should_not have_const("VerySimpleForTests")
    "test".should_not have_const("Spec")
    "omg".should have_const("VerySimpleForTests")
    "omg".should_not have_const("Spec")
  end
end