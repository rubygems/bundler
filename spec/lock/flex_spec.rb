require "spec_helper"

describe "the lockfile format" do

  def be_with_diff(expected)
    # Trim the leading spaces
    spaces = expected[/\A\s+/, 0] || ""
    expected.gsub!(/^#{spaces}/, '')

    simple_matcher "should be" do |given, m|
      m.failure_message = "The lockfile did not match.\n=== Expected:\n" <<
        expected << "\n=== Got:\n" << given << "\n===========\n"
      expected == given
    end
  end

  def lockfile_should_be(expected)
    lock = File.read(bundled_app("Gemfile.lock"))
    lock.should be_with_diff(expected)
  end

  it "generates a simple lockfile for a single source, gem" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rack
    G
  end

  it "generates a simple lockfile for a single source, gem with dependencies" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          rack-obama (1.0)
            rack

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rack-obama
    G
  end

  it "generates a simple lockfile for a single source, gem with a version requirement" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          rack-obama (1.0)
            rack

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rack-obama (>= 1.0)
    G
  end

  it "parses lockfiles w/ crazy shit" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "net-sftp"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          net-sftp (1.1.1)
            net-ssh (>= 1.0.0, < 1.99.0)
          net-ssh (1.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        net-sftp
    G

    should_be_installed "net-sftp 1.1.1", "net-ssh 1.0.0"
  end

  it "generates a simple lockfile for a single pinned source, gem with a version requirement" do
    git = build_git "foo"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}"
    G

    lockfile_should_be <<-G
      GIT
        remote: #{lib_path("foo-1.0")}
        revision: #{git.ref_for('master', 6)}
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo!
    G
  end

  it "serializes global git sources" do
    git = build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}" do
        gem "foo"
      end
    G

    lockfile_should_be <<-G
      GIT
        remote: #{lib_path('foo-1.0')}
        revision: #{git.ref_for('master', 6)}
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo!
    G
  end

  it "generates a lockfile with a ref for a single pinned source, git gem with a branch requirement" do
    git = build_git "foo"
    update_git "foo", :branch => "omg"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}", :branch => "omg"
    G

    lockfile_should_be <<-G
      GIT
        remote: #{lib_path("foo-1.0")}
        revision: #{git.ref_for('omg', 6)}
        branch: omg
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo!
    G
  end

  it "generates a lockfile with a ref for a single pinned source, git gem with a tag requirement" do
    git = build_git "foo"
    update_git "foo", :tag => "omg"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}", :tag => "omg"
    G

    lockfile_should_be <<-G
      GIT
        remote: #{lib_path("foo-1.0")}
        revision: #{git.ref_for('omg', 6)}
        tag: omg
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo!
    G
  end

  it "serializes pinned path sources to the lockfile" do
    build_lib "foo"

    install_gemfile <<-G
      gem "foo", :path => "#{lib_path("foo-1.0")}"
    G

    lockfile_should_be <<-G
      PATH
        remote: #{lib_path("foo-1.0")}
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo!
    G
  end

  it "lists gems alphabetically" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "actionpack"
      gem "rack-obama"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          actionpack (2.3.2)
            activesupport (= 2.3.2)
          activesupport (2.3.2)
          rack (1.0.0)
          rack-obama (1.0)
            rack
          thin (1.0)
            rack

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        actionpack
        rack-obama
        thin
    G
  end

  it "order dependencies of dependencies in alphabetical order" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rails"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          actionmailer (2.3.2)
            activesupport (= 2.3.2)
          actionpack (2.3.2)
            activesupport (= 2.3.2)
          activerecord (2.3.2)
            activesupport (= 2.3.2)
          activeresource (2.3.2)
            activesupport (= 2.3.2)
          activesupport (2.3.2)
          rails (2.3.2)
            actionmailer (= 2.3.2)
            actionpack (= 2.3.2)
            activerecord (= 2.3.2)
            activeresource (= 2.3.2)
            rake
          rake (0.8.7)

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rails
    G
  end

  it "does not add the :require option to the lockfile" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0", :require => "rack/obama"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          rack-obama (1.0)
            rack

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rack-obama (>= 1.0)
    G
  end

  it "does not add the :group option to the lockfile" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0", :group => :test
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          rack-obama (1.0)
            rack

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        rack-obama (>= 1.0)
    G
  end

  it "stores relative paths when the path is provided in a relative fashion" do
    build_lib "foo", :path => bundled_app('foo')

    install_gemfile <<-G
      path "foo"
      gem "foo"
    G

    lockfile_should_be <<-G
      PATH
        remote: foo
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo
    G
  end

  it "stores relative paths when the path is provided in an absolute fashion but is relative" do
    build_lib "foo", :path => bundled_app('foo')

    install_gemfile <<-G
      path File.expand_path("../foo", __FILE__)
      gem "foo"
    G

    lockfile_should_be <<-G
      PATH
        remote: foo
        specs:
          foo (1.0)

      GEM
        specs:

      PLATFORMS
        #{Gem::Platform.local.to_generic}

      DEPENDENCIES
        foo
    G
  end

  it "keeps existing platforms in the lockfile" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)

      PLATFORMS
        java

      DEPENDENCIES
        rack
    G

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G

    platforms = ['java', Gem::Platform.local.to_generic.to_s].sort

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)

      PLATFORMS
        #{platforms[0]}
        #{platforms[1]}

      DEPENDENCIES
        rack
    G
  end

  it "persists the spec's platform to the lockfile" do
    build_gem "platform_specific", "1.0.0", :to_system => true do |s|
      s.platform = Gem::Platform.new('universal-java-16')
    end

    simulate_platform "universal-java-16"

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "platform_specific"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          platform_specific (1.0-java)

      PLATFORMS
        java

      DEPENDENCIES
        platform_specific
    G
  end

  it "does not add duplicate gems" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "activesupport"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          activesupport (2.3.5)
          rack (1.0.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        activesupport
        rack
    G
  end

  it "works correctly with multiple version dependencies" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "> 0.9", "< 1.0"
    G

    lockfile_should_be <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (0.9.1)

      PLATFORMS
        ruby

      DEPENDENCIES
        rack (> 0.9, < 1.0)
    G

  end
end
