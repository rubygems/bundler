require 'pathname'
require Pathname(__FILE__).ascend { |d| h=d+'spec_helper.rb'; break h if h.file? }

describe "Bundler's full install path can point anywhere" do

  {:global => 'global Bundler install_path config', :env => 'environment variable BUNDLE_INSTALL_PATH'}.each do |type, desc|

    describe "running bundle install" do
      describe "when the #{desc} is set" do
        before :each do
          build_lib "rack", "1.0.0", :to_system => true do |s|
            s.write "lib/rack.rb", "raise 'FAIL'"
          end

          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
          G
          @install_folder=[Array.new(6){rand(50).chr}.join].pack("m").chomp
        end

        after :each do
          clean_config
        end

        it "installs gems' when given a gemfile path (sans Gemfile) and install path" do
          ipath = make_install_path(@install_folder)
          Dir.chdir(ipath) do
            env              = set_bundle_install_path(type, @install_folder)
            env['gemfile']    = bundled_app.to_s
            env[:exitstatus] = true
            bundle "install", env
            check exitstatus.should == 0
          end
        end

        it "installs gems' when given a Gemfile and install path" do
          ipath = make_install_path(@install_folder)
          Dir.chdir(ipath) do
            env              = set_bundle_install_path(type, @install_folder)
            env['gemfile']    = (bundled_app + 'Gemfile').to_s
            env[:exitstatus] = true
            bundle "install", env
            check exitstatus.should == 0
          end
        end

        it "installs gems' when gemfile is in working dir and given the same gemfile path (sans Gemfile) and install path" do
          env              = set_bundle_install_path(type, @install_folder)
          env['gemfile']    = bundled_app.to_s
          env[:exitstatus] = true
          bundle "install", env
          check exitstatus.should == 0
        end

        it "installs gems' when gemfile is in working dir and given the same given a Gemfile and install path" do
          env              = set_bundle_install_path(type, @install_folder)
          env['gemfile']    = (bundled_app + 'Gemfile').to_s
          env[:exitstatus] = true
          bundle "install", env
          check exitstatus.should == 0
        end

        it "outputs an error when Gemfile is not pointed to nor is in working directory" do
          ipath = make_install_path(@install_folder)
          Dir.chdir(ipath) do
            env              = set_bundle_install_path(type, @install_folder)
            env[:exitstatus] = true
            bundle "install", env
            check exitstatus.should == 10
            out.should match /Could not locate Gemfile/
          end
        end

        it "outputs an error when Gemfile is pointed to but is not installed" do
          ipath = make_install_path(@install_folder)
          Dir.chdir(ipath) do
            bundle :check, :exitstatus => true, 'gemfile' => bundled_app.to_s
            check @exitstatus.should == 1
            out.should match /Your Gemfile's dependencies could not be satisfied\nInstall missing gems with `bundle install`/
          end
        end
      end
    end

    describe "installing the Gemfile library" do
      describe "when the #{desc} is set" do
        before :each do
          build_lib "rack", "1.0.0", :to_system => true do |s|
            s.write "lib/rack.rb", "raise 'FAIL'"
          end
          @install_folder = [Array.new(6){rand(50).chr}.join].pack("m").chomp
          env = {}
          env['gemfile']    = bundled_app.to_s
          env = env.merge set_bundle_install_path(type, @install_folder)
          ipath             = build_install_path(@install_folder)
          @installed_path   = File.join(ipath, 'gems','rack-1.0.0','lib')
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
          G
          bundle "install", env
          puts "This is err: #{err.inspect}\nThis is out: #{out.inspect}"
        end

        after :each do
          clean_config
        end

        it "outputs an error when Gemfile is pointed to but is not installed" do
          puts "Should bundle check"
          bundle "config gemfile", :exitstatus => true
          puts "This is err: #{err.inspect}\nThis is out: #{out.inspect}"
          bundle :check, :exitstatus => true, 'gemfile' => bundled_app.to_s
          check @exitstatus.should == 0
          out.should match /The Gemfile's dependencies are satisfied/
        end
      end
    end

    describe "requiring the installed library" do
      describe "when the #{desc} is set" do
        before :each do
          build_lib "rack", "1.0.0", :to_system => false do |s|
            s.write "lib/rack.rb", "raise 'FAIL'"
          end
          @install_folder = [Array.new(6){rand(50).chr}.join].pack("m").chomp
          @env = {'no-color' => false}
          @env['gemfile']    = bundled_app.to_s
          @env = @env.merge set_bundle_install_path(type, @install_folder, @env)
          ipath           = build_install_path(@install_folder)
          @installed_path   = File.join(ipath, 'gems','rack-1.0.0','lib')
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
          G
        end

        after :each do
          clean_config
        end

        it "installs nothing to the typical vendor path" do
          bundle "install", @env
          vendored_gems("gems/rack-1.0.0").should_not be_directory
        end

        it "installs nothing to the typical Bundler app path" do
          bundle "install", @env
          bundled_app("gems/rack-1.0.0").should_not be_directory
        end

        it "installs nothing to the typical Bundler app vendor path" do
          bundle "install", @env
          bundled_app('vendor/gems/rack-1.0.0').should_not be_directory
        end

        it "installs nothing to the typical Bundler app system gem path" do
          bundle "install", @env
          system_gem_path('gems/rack-1.0.0').should_not be_directory
        end

        it "installs nothing to the install folder under the typical Bundler app path" do
          bundle "install", @env
          bundled_app("#{@install_folder}/gems/rack-1.0.0").should_not be_directory
        end

        it "installs to the install path directly" do
          $stdout.puts("working dir: #{Dir.pwd}\nDir contents: #{Dir.glob(File.join(Dir.pwd,'**','*'))}")
          bundle "install", @env
          puts "Output: #{out.inspect}"
#          Dir.chdir(bundled_app.to_s) do
#            bundle 'show rack'  # TODO This shoulkd point to the installed path
#          end
#          puts "Output 2: #{out.inspect}"
          puts @installed_path
          puts Dir.exists? @installed_path
          $stdout.puts("install dir: #{build_install_path(@install_folder)}\nDir contents: #{Dir.glob(File.join(build_install_path(@install_folder),'**','*'))}")
          Pathname.new(@installed_path).should be_directory
        end

#        it "necessitates the full path be given to require the library" do
#          opts = set_bundle_install_path(type, @install_folder)
#          should_be_installed "rack 1.0.0", opts
#        end

        it "installs gems' contents to BUNDLE_INSTALL_PATH with #{type}" do
#          set_bundle_install_path(type, bundled_app(@install_path).to_s)
#
#          bundle :install
#
          # bundled_app('vendor/gems/rack-1.0.0').should_not be_directory
#          puts File.expand_path(File.join(bundled_app("#{@install_path}").to_s,"**", "*"))
#          puts Dir.glob(File.join(bundled_app("#{@install_path}").to_s,"**", "*"))
#          bundled_app("#{@install_path}/gems/rack-1.0.0").should be_directory
#          should_be_installed "rack 1.0.0"
        end

      end
    end

  end # each
end