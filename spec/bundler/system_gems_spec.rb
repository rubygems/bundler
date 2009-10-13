require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Using Bundler with system gems" do
  def bundle_rake_with_system_rack
    system_gems 'rack-0.9.1' do
      build_manifest_file <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", :bundle => false
        gem "rake"
      Gemfile

      Dir.chdir(bundled_app) do
        gem_command :bundle
      end

      yield
    end
  end

  it "does not download gems that are not in the bundle" do
    bundle_rake_with_system_rack do
      tmp_gem_path.should have_cached_gems('rake-0.8.7')
      tmp_gem_path.should have_installed_gems('rake-0.8.7')
    end
  end

  it "sets the load path to the system gem" do
    bundle_rake_with_system_rack do
      load_paths = run_in_context("puts $:").split("\n")
      load_paths.should include("#{system_gem_path}/gems/rack-0.9.1/lib")
    end
  end

  it "activates the correct version for the bundle even if new gems are installed" do
    bundle_rake_with_system_rack do
      install_gem("rack-1.0.0")
      load_paths = run_in_context("puts $:").split("\n")
      load_paths.should include("#{system_gem_path}/gems/rack-0.9.1/lib")
    end
  end
end