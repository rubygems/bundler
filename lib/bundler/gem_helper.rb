module Bundler
  class GemHelper

    def self.install_tasks
      dir = caller.find{|c| /Rakefile:/}[/^(.*?)\/Rakefile:/, 1]
      GemHelper.new(dir).install
    end

    attr_reader :spec_path, :base, :name

    def initialize(base, name = nil)
      @base = base
      @name = name || interpolate_name
      @spec_path = File.join(@base, "#{@name}.gemspec")
    end

    def install
      desc 'Build your gem into the pkg directory'
      task 'build' do
        build_gem
      end

      desc 'Install your gem into the pkg directory'
      task 'install' do
        install_gem
      end

      desc 'Push your gem to rubygems'
      task 'push' do
        push_gem
      end
    end

    def build_gem
      file_name = nil
      sh("gem build #{spec_path}") {
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

    def interpolate_name
      gemspecs = Dir[File.join(base, "*.gemspec")]
      raise "Unable to determine name from existing gemspec." unless gemspecs.size == 1

      File.basename(gemspecs.first)[/^(.*)\.gemspec$/, 1]
    end

    def git_push
      sh "git push --all"
      sh "git push --tags"
    end

    def guard_already_tagged
      sh('git tag').split(/\n/).include?(current_version_tag) and raise("This tag has already been committed to the repo.")
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
      raise("Version file could not be found at #{version_file_path}") unless File.exist?(version_file_path)
      File.read(version_file_path)[/V(ERSION|ersion)\s*=\s*(["'])(.*?)\2/, 3]
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
        output = `#{cmd}`
        block.call if block and $? == 0
      }
      [output, $?]
    end
  end
end