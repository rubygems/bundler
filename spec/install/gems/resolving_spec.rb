require File.expand_path('../../../spec_helper', __FILE__)

describe "bundle install with gem sources" do
  describe "install time dependencies" do
    it "installs gems with implicit rake dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "with_implicit_rake_dep"
        gem "another_implicit_rake_dep"
        gem "rake"
      G

      run <<-R
        require 'implicit_rake_dep'
        require 'another_implicit_rake_dep'
        puts IMPLICIT_RAKE_DEP
        puts ANOTHER_IMPLICIT_RAKE_DEP
      R
      out.should == "YES\nYES"
    end

    it "installs gems with a dependency with no type" do
      build_repo2

      path = "#{gem_repo2}/#{Gem::MARSHAL_SPEC_DIR}/actionpack-2.3.2.gemspec.rz"
      spec = Marshal.load(Gem.inflate(File.read(path)))
      spec.dependencies.each do |d|
        d.instance_variable_set(:@type, :fail)
      end
      File.open(path, 'w') do |f|
        f.write Gem.deflate(Marshal.dump(spec))
      end

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "actionpack", "2.3.2"
      G

      should_be_installed "actionpack 2.3.2", "activesupport 2.3.2"
    end

    it "prioritizes local gems over remote gems" do
      build_gem 'rack', '0.0.1', :to_system => true do |s|
        s.add_dependency "activesupport", "2.3.5"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      should_be_installed "rack 0.0.1", "activesupport 2.3.5"
    end

    it "doesn't do crazy" do
      system_gems "rack-0.9.1"

      # Remote gems:
      #  sinatra 0.5 -> depends on rack 0.9.1
      #  sinatra 0.9 -> depends on rack 1.0.0
      #  sinatra 1.0 -> depends on rack 1.0.0
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "sinatra"
      G

      should_be_installed "rack 1.0.0", "sinatra 1.0.0"
    end

    it "doesn't do more crazy" do
      system_gems "rack-0.9.1", "sinatra-0.9"

      # Remote gems:
      #  sinatra 0.5 -> depends on rack 0.9.1
      #  sinatra 0.9 -> depends on rack 1.0.0
      #  sinatra 1.0 -> depends on rack 1.0.0
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "sinatra"
      G

      should_be_installed "rack 1.0.0", "sinatra 0.9"
    end

    it "works with crazy rubygem plugin stuff" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "net_c"
        gem "net_e"
      G

      should_be_installed "net_a 1.0", "net_b 1.0", "net_c 1.0", "net_d 1.0", "net_e 1.0"
    end
  end
end