$:.unshift File.expand_path('../vendor', __FILE__)
require 'open3'
require 'thor'

module Bundler
  class GemHelper
    def self.install_tasks(opts = nil)
      dir = caller.find{|c| /Rakefile:/}[/^(.*?)\/Rakefile:/, 1]
      GemHelper.new(dir, opts && opts[:name]).install
    end

    attr_reader :spec_path, :base, :gemspec

    def initialize(base, name = nil)
      Bundler.ui = UI::Shell.new(Thor::Shell::Color.new)
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
      sh("gem build #{spec_path}") { |out, err|
        raise err if err[/ERROR/]
        file_name = File.basename(built_gem_path)
        FileUtils.mkdir_p(File.join(base, 'pkg'))
        FileUtils.mv(built_gem_path, 'pkg')
        Bundler.ui.confirm "#{name} #{version} built to pkg/#{file_name}"
      }
      File.join(base, 'pkg', file_name)
    end

    def install_gem
      built_gem_path = build_gem
      out, err, code = sh_with_code("gem install #{built_gem_path}")
      if err[/ERROR/]
        Bundler.ui.error err
      else
        Bundler.ui.confirm "#{name} (#{version}) installed"
      end
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
      sh("gem push #{path}")
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
      out, err, code = sh_with_code "git push --quiet#{options}"
      raise err unless err == ''
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
      sh("git ls-files -dm").split("\n").size.zero?
    end

    def tag_version
      sh "git tag -am 'Version #{version}' #{version_tag}"
      Bundler.ui.confirm "Tagged #{tagged_sha} with #{version_tag}"
      yield if block_given?
    rescue
      Bundler.ui.error "Untagged #{tagged_sha} with #{version_tag} due to error"
      sh "git tag -d #{version_tag}"
      raise
    end

    def tagged_sha
      sh("git show-ref --tags #{version_tag}").split(' ').first[0, 8]
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
      out, err, code = sh_with_code(cmd, &block)
      code == 0 ? out : raise(out.empty? ? err : out)
    end

    def sh_with_code(cmd, &block)
      outbuf, errbuf = '', ''
      Dir.chdir(base) {
        stdin, stdout, stderr = *Open3.popen3(cmd)
        if $? == 0
          outbuf, errbuf = stdout.read, stderr.read
          block.call(outbuf, errbuf) if block
        end
      }
      [outbuf, errbuf, $?]
    end
  end
end
