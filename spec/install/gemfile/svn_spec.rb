require "spec_helper"

describe "bundle install with svn sources" do
  describe "when floating on master" do
    before :each do
      build_svn "foo" do |s|
        s.executables = "foobar"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        svn "file://#{lib_path('foo-1.0')}" do
          gem 'foo'
        end
      G
    end

    it "sets up svn gem executables on the path" do
      pending_jruby_shebang_fix
      bundle "exec foobar"
      expect(out).to eq("1.0")
    end

    it "complains if pinned specs don't exist in the svn repo" do
      build_svn "foo"

      install_gemfile <<-G
        gem "foo", "1.1", :svn => "file://#{lib_path('foo-1.0')}"
      G

      expect(out).to include("Source contains 'foo' at: 1.0")
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

      update_svn "foo", "1.1", :path => lib_path("foo-1.0")

      Dir.chdir tmp('bundled_app.bck')
      gemfile tmp('bundled_app.bck/Gemfile'), <<-G
        source "file://#{gem_repo1}"
        svn "file://#{lib_path('foo-1.0')}" do
          gem 'foo'
        end

        gem "rack", "1.0"
      G

      bundle "update foo"

      should_be_installed "foo 1.1", "rack 1.0"
    end

  end

  describe "with an empty svn block" do
    before do
      build_svn "foo"
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"

        svn "file://#{lib_path("foo-1.0")}" do
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
      build_svn "foo"
      @revision = 1
      update_svn "foo" do |s|
        s.write "lib/foo.rb", "puts :CACHE"
      end
    end

    it "works" do
      install_gemfile <<-G
        svn "file://#{lib_path('foo-1.0')}", :ref => "#{@revision}" do
          gem "foo"
        end
      G

      run <<-RUBY
        require 'foo'
      RUBY

      expect(out).not_to eq("CACHE")
    end
  end

  describe "when specifying local override" do
    it "uses the local repository instead of checking a new one out" do
      # We don't generate it because we actually don't need it
      # build_svn "rack", "0.8"

      build_svn "rack", "0.8", :path => lib_path('local-rack') do |s|
        s.write "lib/rack.rb", "puts :LOCAL"
      end

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      bundle %|config local.rack #{File.join(lib_path('local-rack'), '.checkout')}|
      bundle :install
      expect(out).to match(/at #{File.join(lib_path('local-rack'), '.checkout')}/)

      run "require 'rack'"
      expect(out).to eq("LOCAL")
    end

    it "chooses the local repository on runtime" do
      build_svn "rack", "0.8"

      FileUtils.cp_r("#{lib_path('rack-0.8')}/.", lib_path('local-rack'))

      update_svn "rack", "0.8", :path => lib_path('local-rack') do |s|
        s.write "lib/rack.rb", "puts :LOCAL"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      bundle %|config local.rack #{File.join(lib_path('local-rack'), '.checkout')}|
      run "require 'rack'"
      expect(out).to eq("LOCAL")
    end

    it "updates specs on runtime" do
      system_gems "nokogiri-1.4.2"

      build_svn "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      lockfile0 = File.read(bundled_app("Gemfile.lock"))

      FileUtils.cp_r("#{lib_path('rack-0.8')}/.", lib_path('local-rack'))
      update_svn "rack", "0.8", :path => lib_path('local-rack') do |s|
        s.add_dependency "nokogiri", "1.4.2"
      end

      bundle %|config local.rack #{File.join(lib_path('local-rack'), '.checkout')}|
      run "require 'rack'"

      lockfile1 = File.read(bundled_app("Gemfile.lock"))
      expect(lockfile1).not_to eq(lockfile0)
    end

    it "updates ref on install" do
      build_svn "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      lockfile0 = File.read(bundled_app("Gemfile.lock"))

      FileUtils.cp_r("#{lib_path('rack-0.8')}/.", lib_path('local-rack'))
      update_svn "rack", "0.8", :path => lib_path('local-rack')

      bundle %|config local.rack #{File.join(lib_path('local-rack'), '.checkout')}|
      bundle :install

      lockfile1 = File.read(bundled_app("Gemfile.lock"))
      expect(lockfile1).not_to eq(lockfile0)
    end

    it "explodes if given path does not exist on install" do
      build_svn "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      bundle %|config local.rack #{File.join(lib_path('local-rack'), '.checkout')}|
      bundle :install
      expect(out).to match(/Cannot use local override for rack-0.8 because #{Regexp.escape(File.join(lib_path('local-rack'), '.checkout').to_s)} does not exist/)
    end
  end

  describe "specified inline" do
    it "installs from svn even if a newer gem is available elsewhere" do
      build_svn "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack-0.8')}"
      G

      should_be_installed "rack 0.8"
    end

    it "installs dependencies from svn even if a newer gem is available elsewhere" do
      system_gems "rack-1.0.0"

      build_lib "rack", "1.0", :path => lib_path('nested/bar') do |s|
        s.write "lib/rack.rb", "puts 'WIN OVERRIDE'"
      end

      build_svn "foo", :path => lib_path('nested') do |s|
        s.add_dependency "rack", "= 1.0"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo", :svn => "file://#{lib_path('nested')}"
      G

      run "require 'rack'"
      expect(out).to eq('WIN OVERRIDE')
    end

    it "correctly unlocks when changing to a svn source" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      G

      build_svn "rack", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0", :svn => "file://#{lib_path('rack')}"
      G

      should_be_installed "rack 1.0.0"
    end

    it "correctly unlocks when changing to a svn source without versions" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      build_svn "rack", "1.2", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :svn => "file://#{lib_path('rack')}"
      G

      should_be_installed "rack 1.2"
    end
  end

  describe "block syntax" do
    it "pulls all gems from a svn block" do
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
    build_svn "foo"
    @revision = 1
    update_svn "foo" do |s|
      s.write "lib/foo.rb", "puts :CACHE"
    end

    install_gemfile <<-G
      gem "foo", :svn => "file://#{lib_path('foo-1.0')}", :ref => "#{@revision}"
    G

    run <<-RUBY
      require 'foo'
    RUBY

    expect(out).not_to eq("CACHE")
  end

  it "correctly handles cases with invalid gemspecs" do
    build_svn "foo" do |s|
      s.summary = nil
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
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

    build_svn "foo", :path => lib_path("foo") do |s|
      s.write "bin/foo", ""
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "bar", :svn => "file://#{lib_path("foo")}"
      gem "rails", "2.3.2"
    G

    should_be_installed "bar 1.0"
    should_be_installed "rails 2.3.2"
  end

  it "installs from svn even if a rubygems gem is present" do
    build_gem "foo", "1.0", :path => lib_path('fake_foo'), :to_system => true do |s|
      s.write "lib/foo.rb", "raise 'FAIL'"
    end

    build_svn "foo", "1.0"

    install_gemfile <<-G
      gem "foo", "1.0", :svn => "file://#{lib_path('foo-1.0')}"
    G

    should_be_installed "foo 1.0"
  end

  it "fakes the gem out if there is no gemspec" do
    build_svn "foo", :gemspec => false

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "foo", "1.0", :svn => "file://#{lib_path('foo-1.0')}"
      gem "rails", "2.3.2"
    G

    should_be_installed("foo 1.0")
    should_be_installed("rails 2.3.2")
  end

  it "catches svn errors and spits out useful output" do
    gemfile <<-G
      gem "foo", "1.0", :svn => "omgomg"
    G

    bundle :install, :expect_err => true

    expect(out).to include("SVN error:")
    expect(err).to include("omgomg")
  end

  it "doesn't blow up if bundle install is run twice in a row" do
    build_svn "foo"

    gemfile <<-G
      gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
    G

    bundle "install"
    bundle "install"
    expect(exitstatus).to eq(0)
  end

  it "does not duplicate svn gem sources" do
    build_lib "foo", :path => lib_path('nested/foo')
    build_lib "bar", :path => lib_path('nested/bar')

    build_svn "foo", :path => lib_path('nested')
    build_svn "bar", :path => lib_path('nested')

    gemfile <<-G
      gem "foo", :svn => "file://#{lib_path('nested')}"
      gem "bar", :svn => "file://#{lib_path('nested')}"
    G

    bundle "install"
    expect(File.read(bundled_app("Gemfile.lock")).scan('SVN').size).to eq(1)
  end

  describe "bundle install after the remote has been updated" do
    it "installs" do
      build_svn "valim"

      install_gemfile <<-G
        gem "valim", :svn => "file://#{lib_path("valim-1.0")}"
      G

      old_revision = "1"
      update_svn "valim" do |s|
        s.write "lib/valim.rb", "puts #{old_revision}"
      end
      new_revision = "2"

      lockfile = File.read(bundled_app("Gemfile.lock"))
      File.open(bundled_app("Gemfile.lock"), "w") do |file|
        file.puts lockfile.gsub(/revision: #{old_revision}/, "revision: #{new_revision}")
      end

      bundle "install"

      run <<-R
        require "valim"
      R

      expect(out).to eq(old_revision)
    end
  end

  describe "bundle install --deployment with svn sources" do
    it "works" do
      build_svn "valim", :path => lib_path('valim')

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "valim", "= 1.0", :svn => "file://#{lib_path('valim')}"
      G

      simulate_new_machine

      bundle "install --deployment"
      expect(exitstatus).to eq(0)
    end
  end

  describe "gem install hooks" do
    it "runs pre-install hooks" do
      build_svn "foo"
      gemfile <<-G
        gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
      G

      File.open(lib_path("install_hooks.rb"), "w") do |h|
        h.write <<-H
          require 'rubygems'
          Gem.pre_install_hooks << lambda do |inst|
            STDERR.puts "Ran pre-install hook: \#{inst.spec.full_name}"
          end
        H
      end

      bundle :install, :expect_err => true,
        :requires => [lib_path('install_hooks.rb')]
      expect(err).to eq("Ran pre-install hook: foo-1.0")
    end

    it "runs post-install hooks" do
      build_svn "foo"
      gemfile <<-G
        gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
      G

      File.open(lib_path("install_hooks.rb"), "w") do |h|
        h.write <<-H
          require 'rubygems'
          Gem.post_install_hooks << lambda do |inst|
            STDERR.puts "Ran post-install hook: \#{inst.spec.full_name}"
          end
        H
      end

      bundle :install, :expect_err => true,
        :requires => [lib_path('install_hooks.rb')]
      expect(err).to eq("Ran post-install hook: foo-1.0")
    end

    it "complains if the install hook fails" do
      build_svn "foo"
      gemfile <<-G
        gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
      G

      File.open(lib_path("install_hooks.rb"), "w") do |h|
        h.write <<-H
          require 'rubygems'
          Gem.pre_install_hooks << lambda do |inst|
            false
          end
        H
      end

      bundle :install, :expect_err => true,
        :requires => [lib_path('install_hooks.rb')]
      expect(out).to include("failed for foo-1.0")
    end
  end

  context "with an extension" do
    it "installs the extension" do
      build_svn "foo" do |s|
        s.add_dependency "rake"
        s.extensions << "Rakefile"
        s.write "Rakefile", <<-RUBY
          task :default do
            path = File.expand_path("../lib", __FILE__)
            FileUtils.mkdir_p(path)
            File.open("\#{path}/foo.rb", "w") do |f|
              f.puts "FOO = 'YES'"
            end
          end
        RUBY
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "foo", :svn => "file://#{lib_path('foo-1.0')}"
      G

      run <<-R
        require 'foo'
        puts FOO
      R
      expect(out).to eq("YES")
    end
  end

  describe "without svn installed" do
    it "prints a better error message" do
      build_svn "foo"

      install_gemfile <<-G
        svn "file://#{lib_path('foo-1.0')}" do
          gem 'foo'
        end
      G

      bundle "update", :env => {"PATH" => ""}
      expect(out).to include("You need to install svn to be able to use gems from svn repositories. For help installing svn, please refer to SVNook's tutorial at http://svnbook.red-bean.com/en/1.7/svn.intro.install.html")
    end

    it "installs a packaged svn gem successfully" do
      build_svn "foo"

      install_gemfile <<-G
        svn "file://#{lib_path('foo-1.0')}" do
          gem 'foo'
        end
      G
      bundle "package --all"
      simulate_new_machine

      bundle "install", :env => {"PATH" => ""}
      expect(out).to_not include("You need to install svn to be able to use gems from svn repositories.")
      expect(exitstatus).to be_zero
    end
  end
end
