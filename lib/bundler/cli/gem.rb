require 'pathname'

module Bundler
  class CLI::Gem
    attr_reader :options, :gem_name, :thor, :name, :target

    def initialize(options, gem_name, thor)
      @options = options
      @gem_name = gem_name
      @thor = thor

      @name = gem_name.chomp("/") # remove trailing slash if present
      @target = Pathname.pwd.join(name)

      validate_ext_name if options[:ext]
    end

    def run
      underscored_name = name.tr('-', '_')
      namespaced_path = name.tr('-', '/')
      constant_name = name.split('_').map{|p| p[0..0].upcase + p[1..-1] }.join
      constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
      constant_array = constant_name.split('::')
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp

      opts = {
        :name             => name,
        :underscored_name => underscored_name,
        :namespaced_path  => namespaced_path,
        :makefile_path    => "#{underscored_name}/#{underscored_name}",
        :constant_name    => constant_name,
        :constant_array   => constant_array,
        :author           => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email            => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
        :test             => options[:test],
        :ext              => options[:ext]
      }

      templates = {
        "Gemfile.tt" => "Gemfile",
        "gitignore.tt" => ".gitignore",
        "lib/newgem.rb.tt" => "lib/#{namespaced_path}.rb",
        "lib/newgem/version.rb.tt" => "lib/#{namespaced_path}/version.rb",
        "LICENSE.txt.tt" => "LICENSE.txt",
        "newgem.gemspec.tt" => "#{name}.gemspec",
        "consolerc.tt" => ".consolerc",
        "Rakefile.tt" => "Rakefile",
        "README.md.tt" => "README.md"
      }

      templates.merge!("bin/newgem.tt" => "bin/#{name}") if options[:bin]
      templates.merge!(".travis.yml.tt" => ".travis.yml") if options[:test]

      case options[:test]
      when 'rspec'
        templates.merge!(
          "rspec.tt" => ".rspec",
          "spec/spec_helper.rb.tt" => "spec/spec_helper.rb",
          "spec/newgem_spec.rb.tt" => "spec/#{namespaced_path}_spec.rb"
        )
      when 'minitest'
        templates.merge!(
          "test/minitest_helper.rb.tt" => "test/minitest_helper.rb",
          "test/test_newgem.rb.tt" => "test/test_#{namespaced_path}.rb"
        )
      end

      if options[:ext]
        templates.merge!(
          "ext/newgem/extconf.rb.tt" => "ext/#{name}/extconf.rb",
          "ext/newgem/newgem.h.tt" => "ext/#{name}/#{underscored_name}.h",
          "ext/newgem/newgem.c.tt" => "ext/#{name}/#{underscored_name}.c"
        )
      end

      templates.each do |src, dst|
        thor.template("newgem/#{src}", target.join(dst), opts)
      end

      Bundler.ui.info "Initializing git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }

      if options[:edit]
        # Open gemspec in editor
        thor.run("#{options["edit"]} \"#{target.join("#{name}.gemspec")}\"")
      end
    end

    def validate_ext_name
      return unless gem_name.index('-')

      Bundler.ui.error "You have specified a gem name which does not conform to the \n" \
                       "naming guidelines for C extensions. For more information, \n" \
                       "see the 'Extension Naming' section at the following URL:\n" \
                       "http://guides.rubygems.org/gems-with-extensions/\n"
      exit 1
    end

  end
end
