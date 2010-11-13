$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bundler'

module Bundler
  class GemHelper
    def self.install_tasks(opts = nil)
      dir = File.dirname(Rake.application.rakefile_location)
      self.new(dir, opts && opts[:name]).install
    end

    attr_reader :spec_path, :base, :gemspec

    def initialize(base, name = nil)
      Bundler.ui = UI::Shell.new(Thor::Base.shell.new)
      @base = base
      gemspecs = name ? [File.join(base, "#{name}.gemspec")] : Dir[File.join(base, "*.gemspec")]
      raise "Unable to determine name from existing gemspec. Use :name => 'gemname' in #install_tasks to manually set it." unless gemspecs.size == 1
      @spec_path = gemspecs.first
      @gemspec = Bundler.load_gemspec(@spec_path)
    end

    def install
      desc "Build #{name}-#{version}.gem into the pkg directory"
      task 'build' do
        build_gem
      end

      desc "Build and install #{name}-#{version}.gem into system gems"
      task 'install' do
        install_gem
      end

      desc "Create tag #{version_tag} and build and push #{name}-#{version}.gem to Rubygems"
      task 'release' do
        release_gem
      end
    end

    def build_gem
      file_name = nil
      sh("gem build #{spec_path}") { |out, code|
        raise out unless out[/Successfully/]
        file_name = File.basename(built_gem_path)
        FileUtils.mkdir_p(File.join(base, 'pkg'))
        FileUtils.mv(built_gem_path, 'pkg')
        Bundler.ui.confirm "#{name} #{version} built to pkg/#{file_name}"
      }
      File.join(base, 'pkg', file_name)
    end

    def install_gem
      built_gem_path = build_gem
      out, code = sh_with_code("gem install #{built_gem_path}")
      raise "Couldn't install gem, run `gem install #{built_gem_path}' for more detailed output" unless out[/Successfully installed/]
      Bundler.ui.confirm "#{name} (#{version}) installed"
    end

    def release_gem
      guard_clean
      guard_already_tagged
      built_gem_path = build_gem
      tag_version {
        git_push
        rubygem_push(built_gem_path)
      }
    end

    protected
    def rubygem_push(path)
      out, status = sh("gem push #{path}")
      raise "Gem push failed due to lack of RubyGems.org credentials." if out[/Enter your RubyGems.org credentials/]
      Bundler.ui.confirm "Pushed #{name} #{version} to rubygems.org"
    end

    def built_gem_path
      Dir[File.join(base, "#{name}-*.gem")].sort_by{|f| File.mtime(f)}.last
    end

    def git_push
      perform_git_push
      perform_git_push ' --tags'
      Bundler.ui.confirm "Pushed git commits and tags"
    end

    def perform_git_push(options = '')
      cmd = "git push #{options}"
      out, code = sh_with_code(cmd)
      raise "Couldn't git push. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
    end

    def guard_already_tagged
      if sh('git tag').split(/\n/).include?(version_tag)
        raise("This tag has already been committed to the repo.")
      end
    end

    def guard_clean
      clean? or raise("There are files that need to be committed first.")
    end

    def clean?
      out, code = sh_with_code("git diff --exit-code")
      code == 0
    end

    def tag_version
      sh "git tag -a -m \"Version #{version}\" #{version_tag}"
      Bundler.ui.confirm "Tagged #{version_tag}"
      yield if block_given?
    rescue
      Bundler.ui.error "Untagged #{version_tag} due to error"
      sh_with_code "git tag -d #{version_tag}"
      raise
    end

    def version
      gemspec.version
    end

    def version_tag
      "v#{version}"
    end

    def name
      gemspec.name
    end

    def sh(cmd, &block)
      out, code = sh_with_code(cmd, &block)
      code == 0 ? out : raise(out.empty? ? "Running `#{cmd}' failed. Run this command directly for more detailed output." : out)
    end

    def sh_with_code(cmd, &block)
      cmd << " 2>&1"
      outbuf = ''
      Bundler.ui.debug(cmd)
      Dir.chdir(base) {
        outbuf = `#{cmd}`
        if $? == 0
          block.call(outbuf) if block
        end
      }
      [outbuf, $?]
    end
  end
end
