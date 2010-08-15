require 'open3'

module Bundler
  class GemHelper
    def self.install_tasks(opts = nil)
      dir = caller.find{|c| /Rakefile:/}[/^(.*?)\/Rakefile:/, 1]
      GemHelper.new(dir, opts && opts[:name]).install
    end

    attr_reader :spec_path, :base, :name

    def initialize(base, name = nil)
      @base = base
      @name = name || determine_name or raise("Cannot automatically determine the name of your gem. Use :name => 'gemname' in #install_tasks to manually set it.")
      @spec_path = File.join(@base, "#{@name}.gemspec")
    end

    def install
      desc "Build #{name}-#{current_version}.gem into the pkg directory"
      task 'build' do
        build_gem
      end

      desc "Build and install #{name}-#{current_version}.gem into system gems"
      task 'install' do
        install_gem
      end

      desc "Create tag #{current_version_tag} and build and push #{name}-#{current_version}.gem to Rubygems"
      task 'push' do
        push_gem
      end
    end

    def build_gem
      file_name = nil
      sh("gem build #{spec_path}") { |out, err|
        raise err if err[/ERROR/]
        file_name = File.basename(built_gem_path)
        FileUtils.mkdir_p(File.join(base, 'pkg'))
        FileUtils.mv(built_gem_path, 'pkg')
      }
      File.join(base, 'pkg', file_name)
    end

    def install_gem
      built_gem_path = build_gem
      sh("gem install #{built_gem_path}")
    end

    def push_gem
      guard_clean
      guard_already_tagged
      tag_version {
        git_push
        rubygem_push(build_gem)
      }
    end

    protected
    def rubygem_push(path)
      sh("gem push #{path}")
    end

    def built_gem_path
      Dir[File.join(base, "#{name}-*.gem")].sort_by{|f| File.mtime(f)}.last
    end

    def determine_name
      gemspecs = Dir[File.join(base, "*.gemspec")]
      raise "Unable to determine name from existing gemspec." unless gemspecs.size == 1
      Bundler.load_gemspec(gemspecs.first).name
    end

    def git_push
      sh "git push --all"
      sh "git push --tags"
    end

    def guard_already_tagged
      if sh('git tag').split(/\n/).include?(current_version_tag)
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
      sh "git tag #{current_version_tag}"
      yield if block_given?
    rescue
      sh "git tag -d #{current_version_tag}"
      raise
    end

    def current_version
      file = [version_file_path, library_file_path].find{|p| File.exist?(p) }
      version = File.read(file)[/V(?i:ersion)\s*=\s*(["'])(.*?)\1/, 2]

      unless version
        raise("Version could not be found in lib/#{name}/version.rb")
      else
        version
      end
    end

    def library_file_path
      File.join(base, 'lib', "#{name}.rb")
    end

    def version_file_path
      File.join(base, 'lib', name, 'version.rb')
    end

    def current_version_tag
      "v#{current_version}"
    end

    def sh(cmd, &block)
      output, code = sh_with_code(cmd, &block)
      code == 0 ? output : raise(output)
    end

    def sh_with_code(cmd, &block)
      output = ''
      Dir.chdir(base) {
        stdin, stdout, stderr = *Open3.popen3(cmd)
        if $? == 0
          output = stdout.read
          block.call(output, stderr.read) if block
        end
      }
      [output, $?]
    end
  end
end