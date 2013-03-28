require 'bundler/ui'
require 'bundler'

module Bundler
  class GemHelper
    include Rake::DSL if defined? Rake::DSL

    def self.install_tasks(opts = {})
      Bundler.ui ||= UI::Shell.new(options)
      helper = self.new(opts[:dir], opts[:name])
      @last_gemspec = helper.gemspec
      helper.install
    end

    def self.gemspec
      Bundler.ui.warn "Bundler::GemHelper.gemspec is deprecated. Please use " \
        "Bundler::GemHelper.new yourself. See bundler/gem_tasks.rb for more."
      yield @last_gemspec if block_given?
      @last_gemspec
    end

    attr_reader :base, :gemspec, :gem_path, :spec_path

    def initialize(base = nil, name = nil)
      @base = base || Dir.pwd
      @spec_path = find_gemspec(@base, name)
      @gemspec = Bundler.load_gemspec(spec_path)
      @gem_path = "#{@gemspec.name}-#{@gemspec.version}.gem"
    end

    def find_gemspec(base, name)
      if name
        gemspecs = [File.join(base, "#{name}.gemspec")]
      else
        gemspecs = Dir[File.join(base, "{,*}.gemspec")]
      end

      if gemspecs.size != 1
        raise "Unable to determine name from existing gemspec. Use :name => " \
          "'gemname' in #install_tasks to manually set it."
      end

      gemspecs.first
    end

    def name
      gemspec.name
    end

    def version
      gemspec.version
    end

    def no_gem_push?
      %w(n no nil false off 0).include?(ENV['gem_push'].to_s.downcase)
    end

    def install
      directory "pkg"

      desc "Build #{gem_path} into the pkg directory."
      task :build => "pkg" do
        sh "gem build -V '#{spec_path}'"
        mv gem_path, "pkg/#{gem_path}"
        Bundler.ui.confirm "#{name} #{version} built to pkg/#{gem_path}."
      end

      desc "Build and install #{gem_path} into system gems."
      task :install => :build do
        Dir.chdir "pkg" do
          sh "gem install '#{gem_path}'"
        end
      end

      desc "Create tag v#{version} and build and push #{gem_path} to Rubygems"
      task :release => [:tag, :git_push, :build, :push]

      task :tag => :check_committed do
        if %x(git tag).split(/\n/).include?("v#{version}")
          Bundler.ui.confirm "Tag v#{version} has already been created."
        else
          sh "git tag -am 'Version #{version}' v#{version}"
          Bundler.ui.confirm "Tagged v#{version}."
        end
      end

      task :git_push do
        sh "git push"
        sh "git push --tags"
        Bundler.ui.confirm "Pushed git commits and tags."
      end

      task :push do
        return if no_gem_push?

        if !Pathname.new("~/.gem/credentials").expand_path.exist?
          Bundler.ui.error "Your rubygems.org credentials aren't set. " \
            "Run `gem push` at least once to set them first." && exit(1)
        end

        sh "gem push 'pkg/#{gem_path}'"
        Bundler.ui.confirm "Pushed #{name} #{version} to rubygems.org."
      end

      task :check_committed do
        # Unfortunately --porcelain depends on git 1.7 :(
        # sh('test -z "$(git status --porcelain)"') do |ok|
        sh('git diff --quiet && git diff --cached --quiet') do |ok|
          ok || ( Bundler.ui.error("You have uncommitted changes, " \
            "please commit them first.") && exit(1) )
        end
      end

    end

  end
end
