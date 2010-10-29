require "spec_helper"

describe "bundle install with git sources" do
  describe "when floating on master" do
    before :each do
      build_git "foo" do |s|
        s.executables = "foobar"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        git "#{lib_path('foo-1.0')}" do
          gem 'foo'
        end
      G
    end

    it "fetches gems" do
      should_be_installed("foo 1.0")

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end

    it "caches the git repo" do
      Dir["#{default_bundle_path}/cache/bundler/git/foo-1.0-*"].should have(1).item
    end

    it "does not update the git source implicitly" do
      update_git "foo"

      in_app_root2 do
        install_gemfile bundled_app2("Gemfile"), <<-G
          git "#{lib_path('foo-1.0')}" do
            gem 'foo'
          end
        G
      end

      in_app_root do
        run <<-RUBY
          require 'foo'
          puts "fail" if defined?(FOO_PREV_REF)
        RUBY

        out.should be_empty
      end
    end

    it "setups executables" do
      pending_jruby_shebang_fix
      bundle "exec foobar"
      out.should == "1.0"
    end

    it "complains if pinned specs don't exist in the git repo" do
      build_git "foo"

      install_gemfile <<-G
        gem "foo", "1.1", :git => "#{lib_path('foo-1.0')}"
      G

      out.should include("Source contains 'foo' at: 1.0")
    end

    it "still works after moving the application directory" do
      bundle "install --path vendor/bundle"
      FileUtils.mv bundled_app, tmp('bundled_app.bck')

      Dir.chdir tmp('bundled_app.bck')
      should_be_installed "foo 1.0"
    end

    it "can still install after moving the application directory" do
      bundle "install --path vendor/bundle"
      FileUtils.mv bundled_app, tmp('bundled_app.bck')

      update_git "foo", "1.1", :path => lib_path("foo-1.0")

      Dir.chdir tmp('bundled_app.bck')
      gemfile tmp('bundled_app.bck/Gemfile'), <<-G
        source "file://#{gem_repo1}"
        git "#{lib_path('foo-1.0')}" do
          gem 'foo'
        end

        gem "rack", "1.0"
      G

      bundle "update foo"

      should_be_installed "foo 1.1", "rack 1.0"
    end

  end

  describe "with an empty git block" do
    before do
      build_git "foo"
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"

        git "#{lib_path("foo-1.0")}" do
          # this page left intentionally blank
        end
      G
    end

    it "does not explode" do
      bundle "install"
      should_be_installed "rack 1.0"
    end
  end

  describe "when specifying a revision" do
    before(:each) do
      build_git "foo"
      @revision = revision_for(lib_path("foo-1.0"))
      update_git "foo"
    end

    it "works" do
      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}", :ref => "#{@revision}" do
          gem "foo"
        end
      G

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end

    it "works when the revision is a symbol" do
      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}", :ref => #{@revision.to_sym.inspect} do
          gem "foo"
        end
      G
      check err.should == ""

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end
  end

  describe "specified inline" do
    # TODO: Figure out how to write this test so that it is not flaky depending
    #       on the current network situation.
    # it "supports private git URLs" do
    #   gemfile <<-G
    #     gem "thingy", :git => "git@notthere.fallingsnow.net:somebody/thingy.git"
    #   G
    #
    #   bundle :install, :expect_err => true
    #
    #   # p out
    #   # p err
    #   puts err unless err.empty? # This spec fails randomly every so often
    #   err.should include("notthere.fallingsnow.net")
    #   err.should include("ssh")
    # end

    it "installs from git even if a newer gem is available elsewhere" do
      build_git "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path('rack-0.8')}"
      G

      should_be_installed "rack 0.8"
    end

    it "installs dependencies from git even if a newer gem is available elsewhere" do
      system_gems "rack-1.0.0"

      build_lib "rack", "1.0", :path => lib_path('nested/bar') do |s|
        s.write "lib/rack.rb", "puts 'WIN OVERRIDE'"
      end

      build_git "foo", :path => lib_path('nested') do |s|
        s.add_dependency "rack", "= 1.0"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo", :git => "#{lib_path('nested')}"
      G

      run "require 'rack'"
      out.should == 'WIN OVERRIDE'
    end

    it "correctly unlocks when changing to a git source" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      G

      build_git "rack", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0", :git => "#{lib_path('rack')}"
      G

      should_be_installed "rack 1.0.0"
    end

    it "correctly unlocks when changing to a git source without versions" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      build_git "rack", "1.2", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path('rack')}"
      G

      should_be_installed "rack 1.2"
    end
  end

  describe "block syntax" do
    it "pulls all gems from a git block" do
      build_lib "omg", :path => lib_path('hi2u/omg')
      build_lib "hi2u", :path => lib_path('hi2u')

      install_gemfile <<-G
        path "#{lib_path('hi2u')}" do
          gem "omg"
          gem "hi2u"
        end
      G

      should_be_installed "omg 1.0", "hi2u 1.0"
    end
  end

  it "uses a ref if specified" do
    build_git "foo"
    @revision = revision_for(lib_path("foo-1.0"))
    update_git "foo"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}", :ref => "#{@revision}"
    G

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end

  it "correctly handles cases with invalid gemspecs" do
    build_git "foo" do |s|
      s.summary = nil
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "foo", :git => "#{lib_path('foo-1.0')}"
      gem "rails", "2.3.2"
    G

    should_be_installed "foo 1.0"
    should_be_installed "rails 2.3.2"
  end

  it "runs the gemspec in the context of its parent directory" do
    build_lib "bar", :path => lib_path("foo/bar"), :gemspec => false do |s|
      s.write lib_path("foo/bar/lib/version.rb"), %{BAR_VERSION = '1.0'}
      s.write "bar.gemspec", <<-G
        $:.unshift Dir.pwd # For 1.9
        require 'lib/version'
        Gem::Specification.new do |s|
          s.name        = 'bar'
          s.version     = BAR_VERSION
          s.summary     = 'Bar'
          s.files       = Dir["lib/**/*.rb"]
        end
      G
    end

    build_git "foo", :path => lib_path("foo") do |s|
      s.write "bin/foo", ""
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "bar", :git => "#{lib_path("foo")}"
      gem "rails", "2.3.2"
    G

    should_be_installed "bar 1.0"
    should_be_installed "rails 2.3.2"
  end

  it "installs from git even if a rubygems gem is present" do
    build_gem "foo", "1.0", :path => lib_path('fake_foo'), :to_system => true do |s|
      s.write "lib/foo.rb", "raise 'FAIL'"
    end

    build_git "foo", "1.0"

    install_gemfile <<-G
      gem "foo", "1.0", :git => "#{lib_path('foo-1.0')}"
    G

    should_be_installed "foo 1.0"
  end

  it "fakes the gem out if there is no gemspec" do
    build_git "foo", :gemspec => false

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "foo", "1.0", :git => "#{lib_path('foo-1.0')}"
      gem "rails", "2.3.2"
    G

    should_be_installed("foo 1.0")
    should_be_installed("rails 2.3.2")
  end

  it "catches git errors and spits out useful output" do
    gemfile <<-G
      gem "foo", "1.0", :git => "omgomg"
    G

    bundle :install, :expect_err => true

    out.should include("An error has occurred in git")
    err.should include("fatal")
    err.should include("omgomg")
    err.should include("fatal: The remote end hung up unexpectedly")
  end

  it "works when the gem path has spaces in it" do
    build_git "foo", :path => lib_path('foo space-1.0')

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo space-1.0')}"
    G

    should_be_installed "foo 1.0"
  end

  it "handles repos that have been force-pushed" do
    build_git "forced", "1.0"

    install_gemfile <<-G
      git "#{lib_path('forced-1.0')}" do
        gem 'forced'
      end
    G
    should_be_installed "forced 1.0"

    update_git "forced" do |s|
      s.write "lib/forced.rb", "FORCED = '1.1'"
    end

    bundle "update"
    should_be_installed "forced 1.1"

    Dir.chdir(lib_path('forced-1.0')) do
      `git reset --hard HEAD^`
    end

    bundle "update"
    should_be_installed "forced 1.0"
  end

  it "ignores submodules if :submodule is not passed" do
    build_git "submodule", "1.0"
    build_git "has_submodule", "1.0" do |s|
      s.add_dependency "submodule"
    end
    Dir.chdir(lib_path('has_submodule-1.0')) do
      `git submodule add #{lib_path('submodule-1.0')} submodule-1.0`
      `git commit -m "submodulator"`
    end

    install_gemfile <<-G, :expect_err => true
      git "#{lib_path('has_submodule-1.0')}" do
        gem "has_submodule"
      end
    G
    out.should =~ /Could not find gem 'submodule'/

    should_not_be_installed "has_submodule 1.0", :expect_err => true
  end

  it "handles repos with submodules" do
    build_git "submodule", "1.0"
    build_git "has_submodule", "1.0" do |s|
      s.add_dependency "submodule"
    end
    Dir.chdir(lib_path('has_submodule-1.0')) do
      `git submodule add #{lib_path('submodule-1.0')} submodule-1.0`
      `git commit -m "submodulator"`
    end

    install_gemfile <<-G
      git "#{lib_path('has_submodule-1.0')}", :submodules => true do
        gem "has_submodule"
      end
    G

    should_be_installed "has_submodule 1.0"
  end

  it "handles implicit updates when modifying the source info" do
    git = build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}" do
        gem "foo"
      end
    G

    update_git "foo"
    update_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}", :ref => "#{git.ref_for('HEAD^')}" do
        gem "foo"
      end
    G

    run <<-RUBY
      require 'foo'
      puts "WIN" if FOO_PREV_REF == '#{git.ref_for("HEAD^^")}'
    RUBY

    out.should == "WIN"
  end

  it "does not to a remote fetch if the revision is cached locally" do
    build_git "foo"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}"
    G

    FileUtils.rm_rf(lib_path('foo-1.0'))

    bundle "install"
    out.should_not =~ /updating/i
  end

  it "doesn't blow up if bundle install is run twice in a row" do
    build_git "foo"

    gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}"
    G

    bundle "install"
    bundle "install", :exitstatus => true
    exitstatus.should == 0
  end

  describe "switching sources" do
    it "doesn't explode when switching Path to Git sources" do
      build_gem "foo", "1.0", :to_system => true do |s|
        s.write "lib/foo.rb", "raise 'fail'"
      end
      build_lib "foo", "1.0", :path => lib_path('bar/foo')
      build_git "bar", "1.0", :path => lib_path('bar') do |s|
        s.add_dependency 'foo'
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "bar", :path => "#{lib_path('bar')}"
      G

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "bar", :git => "#{lib_path('bar')}"
      G

      should_be_installed "foo 1.0", "bar 1.0"
    end

    it "doesn't explode when switching Gem to Git source" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack-obama"
        gem "rack", "1.0.0"
      G

      build_git "rack", "1.0" do |s|
        s.write "lib/new_file.rb", "puts 'USING GIT'"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack-obama"
        gem "rack", "1.0.0", :git => "#{lib_path("rack-1.0")}"
      G

      run "require 'new_file'"
      out.should == "USING GIT"
    end
  end

  describe "bundle install after the remote has been updated" do
    it "installs" do
      build_git "valim"

      install_gemfile <<-G
        gem "valim", :git => "file://#{lib_path("valim-1.0")}"
      G

      old_revision = revision_for(lib_path("valim-1.0"))
      update_git "valim"
      new_revision = revision_for(lib_path("valim-1.0"))

      lockfile = File.read(bundled_app("Gemfile.lock"))
      File.open(bundled_app("Gemfile.lock"), "w") do |file|
        file.puts lockfile.gsub(/revision: #{old_revision}/, "revision: #{new_revision}")
      end

      bundle "install"

      run <<-R
        require "valim"
        puts VALIM_PREV_REF
      R

      out.should == old_revision
    end
  end

  describe "bundle install --deployment with git sources" do
    it "works" do
      build_git "valim", :path => lib_path('valim')

      install_gemfile <<-G
        source "file://#{gem_repo1}"

        gem "valim", "= 1.0", :git => "#{lib_path('valim')}"
      G

      simulate_new_machine

      bundle "install --deployment", :exitstatus => true
      exitstatus.should == 0
    end
  end
end
