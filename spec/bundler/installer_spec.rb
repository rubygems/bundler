require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Installing gems" do

  describe "the bundle directory" do
    def setup
      @manifest = build_manifest <<-Gemfile
        sources.clear
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        bundle_path "#{tmp_file('hello')}"
        gem "rails"
      Gemfile
    end

    it "creates the bundle directory if it does not exist" do
      setup
      @manifest.install
      tmp_file("hello").should have_cached_gems("rails-2.3.2")
    end

    it "uses the bundle directory if it is empty" do
      tmp_file("hello").mkdir
      setup
      @manifest.install
      tmp_file("hello").should have_cached_gems("rails-2.3.2")
    end

    it "uses the bundle directory if it is a valid gem repo" do
      tmp_file("hello").mkdir
      %w(cache doc gems environments specifications).each { |dir| tmp_file("hello", dir).mkdir }
      setup
      @manifest.install
      tmp_file("hello").should have_cached_gems("rails-2.3.2")
    end

    it "does not use the bundle directory if it is not a valid gem repo" do
      tmp_file("hello").mkdir
      FileUtils.touch(tmp_file("hello", "fail"))
      lambda {
        setup
      }.should raise_error(Bundler::InvalidRepository)
    end
  end
end
#
# describe "Bundler::Installer" do
#
#   before(:each) do
#     pending
#   end
#
#   before(:each) do
#     @finder = Bundler::Finder.new("file://#{gem_repo1}", "file://#{gem_repo2}")
#   end
#
#   describe "without native gems" do
#     before(:each) do
#       @bundle = @finder.resolve(build_dep('rails', '>= 0'))
#       @bundle.download(tmp_dir)
#     end
#
#     it "raises an ArgumentError if the path does not exist" do
#       lambda { Bundler::Installer.install(tmp_dir.join("omgomgbadpath")) }.should raise_error(ArgumentError)
#     end
#
#     it "raises an ArgumentError if the path does not contain a 'cache' directory" do
#       lambda { Bundler::Installer.install(gem_repo1) }.should raise_error(ArgumentError)
#     end
#
#     describe "installing gems" do
#
#       before(:each) do
#         FileUtils.rm_rf(tmp_file("gems"))
#         FileUtils.rm_rf(tmp_file("specifications"))
#       end
#
#       it "installs the bins in the directory you specify" do
#         FileUtils.mkdir_p tmp_file("omgbinz")
#         @environment = Bundler::Installer.install(tmp_dir, tmp_file("omgbinz"))
#         File.exist?(tmp_file("omgbinz", "rails")).should be_true
#       end
#
#       it "does not modify any .gemspec files that are to be installed if a directory of the same name exists" do
#         dir = tmp_file("gems", "rails-2.3.2")
#         FileUtils.mkdir_p(dir)
#         FileUtils.mkdir_p(tmp_file("specifications"))
#         spec = tmp_file("specifications", "rails-2.3.2.gemspec")
#         FileUtils.touch(spec)
#         lambda { Bundler::Installer.install(tmp_dir) }.should_not change { [File.mtime(dir), File.mtime(spec)] }
#       end
#
#       it "deletes a .gemspec file that is to be installed if a directory of the same name does not exist" do
#         spec = tmp_file("specifications", "rails-2.3.2.gemspec")
#         FileUtils.mkdir_p(tmp_file("specifications"))
#         FileUtils.touch(spec)
#         lambda { Bundler::Installer.install(tmp_dir) }.should change { File.mtime(spec) }
#       end
#
#       it "deletes a directory that is to be installed if a .gemspec of the same name does not exist" do
#         dir = tmp_file("gems", "rails-2.3.2")
#         FileUtils.mkdir_p(dir)
#         lambda { Bundler::Installer.install(tmp_dir) }.should change { File.mtime(dir) }
#       end
#
#       it "keeps bin files for already installed gems" do
#         Bundler::Installer.install(tmp_dir)
#         Bundler::Installer.install(tmp_dir)
#         tmp_file("bin", "rails").should exist
#       end
#     end
#
#     describe "after installing gems" do
#
#       before(:each) do
#         @environment = Bundler::Installer.install(tmp_dir)
#       end
#
#       it "each thing in the bundle has a directory in gems" do
#         @bundle.each do |spec|
#           Dir[File.join(tmp_dir, 'gems', "#{spec.full_name}")].should have(1).item
#         end
#       end
#
#       it "creates a specification for each gem" do
#         @bundle.each do |spec|
#           Dir[File.join(tmp_dir, 'specifications', "#{spec.full_name}.gemspec")].should have(1).item
#         end
#       end
#
#       it "copies gem executables to a specified path" do
#         File.exist?(File.join(tmp_dir, 'bin', 'rails')).should be_true
#       end
#     end
#
#     it "outputs a logger message for each gem that is installed" do
#       @environment = Bundler::Installer.install(tmp_dir)
#       @bundle.each do |spec|
#         @log_output.should have_log_message("Installing #{spec.full_name}.gem")
#       end
#     end
#   end
#
#   describe "with native gems" do
#
#     it "compiles binary gems" do
#       FileUtils.rm_rf(tmp_dir)
#       @bundle = @finder.resolve(build_dep('json', '>= 0'))
#       @bundle.download(tmp_dir)
#       Bundler::Installer.install(tmp_dir)
#       Dir[File.join(tmp_dir, 'gems', "json-*", "**", "*.bundle")].should have_at_least(1).item
#     end
#
#   end
# end
