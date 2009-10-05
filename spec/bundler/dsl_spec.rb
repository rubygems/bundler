require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler DSL" do

  def have_const(const)
    simple_matcher "have const" do |given, matcher|
      matcher.failure_message = "Could not find constant '#{const}' in environment: '#{given}'"
      out = run_in_context "Bundler.require_env #{given.inspect} ; p !!defined?(#{const})"
      out == "true"
    end
  end

  it "supports only blocks" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"

      gem "activerecord"

      only :test do
        gem "rspec", :require_as => "spec"
        gem "webrat"
      end
    Gemfile

    "default".should have_const("ActiveRecord")
    "default".should_not have_const("Spec")
    "default".should_not have_const("Webrat")

    "test".should have_const("ActiveRecord")
    "test".should have_const("Spec")
    "test".should have_const("Webrat")
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
        gem "webrat"
        only :test do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "test".should have_const("Webrat")
    "test".should have_const("Spec")
    "staging".should have_const("Webrat")
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
        gem "webrat"
      end
    Gemfile

    "default".should have_const("ActiveRecord")
    "default".should have_const("Spec")
    "default".should have_const("Webrat")

    "test".should have_const("ActiveRecord")
    "test".should_not have_const("Spec")
    "test".should_not have_const("Webrat")
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
        gem "webrat"
        except :omg do
          gem "rspec", :require_as => "spec"
        end
      end
    Gemfile

    "default".should have_const("Spec")
    "default".should have_const("Webrat")
    "test".should_not have_const("Webrat")
    "test".should_not have_const("Spec")
    "omg".should have_const("Webrat")
    "omg".should_not have_const("Spec")
  end
end