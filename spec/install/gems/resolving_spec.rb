# frozen_string_literal: true
require "spec_helper"

describe "bundle install with install-time dependencies" do
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
    expect(out).to eq("YES\nYES")
  end

  it "installs gems with a dependency with no type" do
    build_repo2

    path = "#{gem_repo2}/#{Gem::MARSHAL_SPEC_DIR}/actionpack-2.3.2.gemspec.rz"
    spec = Marshal.load(Gem.inflate(File.read(path)))
    spec.dependencies.each do |d|
      d.instance_variable_set(:@type, :fail)
    end
    File.open(path, "w") do |f|
      f.write Gem.deflate(Marshal.dump(spec))
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "actionpack", "2.3.2"
    G

    should_be_installed "actionpack 2.3.2", "activesupport 2.3.2"
  end

  describe "with crazy rubygem plugin stuff" do
    it "installs plugins" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "net_b"
      G

      should_be_installed "net_b 1.0"
    end

    it "installs plugins depended on by other plugins" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "net_a"
      G

      should_be_installed "net_a 1.0", "net_b 1.0"
    end

    it "installs multiple levels of dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "net_c"
        gem "net_e"
      G

      should_be_installed "net_a 1.0", "net_b 1.0", "net_c 1.0", "net_d 1.0", "net_e 1.0"
    end

    context "with ENV['DEBUG_RESOLVER'] set" do
      it "produces debug output" do
        gemfile <<-G
          source "file://#{gem_repo1}"
          gem "net_c"
          gem "net_e"
        G

        resolve_output = capture(:stdout) do
          bundle :install, :env => { "DEBUG_RESOLVER" => "1" }
        end

        expect(resolve_output).to include("Creating possibility state for net_c")
      end
    end

    context "with ENV['DEBUG_RESOLVER_TREE'] set" do
      it "produces debug output" do
        gemfile <<-G
          source "file://#{gem_repo1}"
          gem "net_c"
          gem "net_e"
        G

        resolve_output = capture(:stdout) do
          bundle :install, :env => { "DEBUG_RESOLVER_TREE" => "1" }
        end

        expect(resolve_output).to include(" net_b")
        expect(resolve_output).to include(" net_build_extensions (1.0)")
      end
    end
  end

  describe "when a required ruby version" do
    context "allows only an older version" do
      it "installs the older version" do
        update_repo gem_repo1 do
          build_gem "rack", "9001.0.0" do |s|
            s.required_ruby_version = "> 9000"
          end
        end

        install_gemfile <<-G, :artifice => "compact_index"
          ruby "#{RUBY_VERSION}"
          source "file://#{gem_repo1}"
          gem 'rack'
        G

        expect(out).to_not include("rack-9001.0.0 requires ruby version > 9000")
        should_be_installed("rack 1.0")
      end
    end

    context "allows no versions" do
      it "raises an error during resolution" do
        update_repo gem_repo1 do
          build_gem "require_ruby" do |s|
            s.required_ruby_version = "> 9000"
          end
        end

        install_gemfile <<-G, :artifice => "compact_index"
          ruby "#{RUBY_VERSION}"
          source "file://#{gem_repo1}"
          gem 'require_ruby'
        G

        expect(out).to_not include("Gem::InstallError: require_ruby requires Ruby version > 9000")
        nice_error = <<-E.strip.gsub(/^ {8}/, "")
          Fetching source index from file:#{gem_repo1}/
          Resolving dependencies...
          Bundler could not find compatible versions for gem "require_ruby":
            In Gemfile:
              ruby (= #{RUBY_VERSION})

              require_ruby was resolved to 1.0, which depends on
                ruby (> 9000)
        E
        expect(out).to eq(nice_error)
      end
    end
  end

  describe "when a required rubygems version disallows a gem" do
    it "does not try to install those gems" do
      update_repo gem_repo1 do
        build_gem "require_rubygems" do |s|
          s.required_rubygems_version = "> 9000"
        end
      end

      install_gemfile <<-G, :artifice => "compact_index"
        source "file://#{gem_repo1}"
        gem 'require_rubygems'
      G

      expect(out).to_not include("Gem::InstallError: require_rubygems requires RubyGems version > 9000")
      expect(out).to include("require_rubygems-1.0 requires rubygems version > 9000, which is incompatible with the current version, #{Gem::VERSION}")
    end
  end
end
