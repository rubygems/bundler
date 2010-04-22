require "spec_helper"

describe "bundle install with gem sources" do
  describe "when locked" do
    before(:each) do
      system_gems "rack-0.9.1" do
        gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack"
        G

        bundle :lock
      end
    end

    it "works" do
      system_gems [] do
        bundle :install
        should_be_installed "rack 0.9.1"
      end
    end

    it "allows --relock to update the dependencies" do
      pending_bundle_update
      system_gems "rack-0.9.1" do
        bundle "install --relock"
        should_be_installed "rack 1.0.0"
      end
    end

    it "regenerates .bundle/environment.rb if missing" do
      bundled_app('.bundle/environment.rb').delete
      system_gems [] do
        bundle :install
        bundled_app('.bundle/environment.rb').should exist
        should_be_installed "rack 0.9.1"
      end
    end
  end

  describe "when locked and installed with --without" do
    before(:each) do
      build_repo2
      system_gems "rack-0.9.1" do
        install_gemfile <<-G, :without => :rack
          source "file://#{gem_repo2}"
          gem "rack"

          group :rack do
            gem "rack_middleware"
          end
        G

        bundle :lock
      end
    end

    it "uses the correct versions even if --without was used on the original" do
      should_be_installed "rack 0.9.1"
      should_not_be_installed "rack_middleware 1.0"
      simulate_new_machine

      bundle :install

      should_be_installed "rack 0.9.1"
      should_be_installed "rack_middleware 1.0"
    end

    it "regenerates the environment.rb if install is called twice on a locked repo" do
      run "begin; require 'rack_middleware'; rescue LoadError; puts 'WIN'; end", :lite_runtime => true
      check out.should == "WIN"

      bundle :install

      run "require 'rack_middleware'; puts RACK_MIDDLEWARE", :lite_runtime => true
      out.should == "1.0"
    end

    it "does not hit the remote a second time" do
      FileUtils.rm_rf gem_repo2
      bundle "install --without rack"
      err.should be_empty
    end
  end
end