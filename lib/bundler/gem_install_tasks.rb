module Bundler
  class GemHelper
    include Rake::DSL if defined? Rake::DSL

    def self.install_tasks(opts = {})
      dir = opts[:dir] || Dir.pwd
      self.new(dir, opts[:name]).install_tasks
    end

    def install_tasks
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
      sh("gem build -V '#{spec_path}'") { |out, code|
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
      out, _ = sh_with_code("gem install '#{built_gem_path}'")
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
  end
end
