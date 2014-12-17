require 'pathname'

module Bundler
  class CLI::Gem
    attr_reader :options, :gem_name, :thor, :name, :target

    def initialize(options, gem_name, thor)
      @options = options
      @gem_name = resolve_name(gem_name)
      @thor = thor

      @name = @gem_name
      @target = Pathname.pwd.join(gem_name)

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
        "newgem.gemspec.tt" => "#{name}.gemspec",
        "Rakefile.tt" => "Rakefile",
        "README.md.tt" => "README.md"
      }

      if ask_and_set(:coc, "Do you want to include Code Of Conduct?")
        templates.merge!("CODE_OF_CONDUCT.md.tt" => "CODE_OF_CONDUCT.md")
      end

      if ask_and_set(:mit, "Do you want to license your code permissively under the MIT license (http://choosealicense.com/licenses/mit/)?")
        templates.merge!("LICENSE.txt.tt" => "LICENSE.txt")
      end

      if test_framework = ask_and_set_test_framework
        templates.merge!(".travis.yml.tt" => ".travis.yml")

        case test_framework
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
      end

      templates.merge!("bin/newgem.tt" => "bin/#{name}") if options[:bin]

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

    private

    def resolve_name(name)
      Pathname.pwd.join(name).basename.to_s
    end

    def ask_and_set(key, message)
      result = options[key]
      if !Bundler.settings.all.include?("gem.#{key}")
        if result.nil?
          result = Bundler.ui.ask("#{message} (y/n):") == "y"
        end

        Bundler.settings.set_global("gem.#{key}", result)
      end

      result || Bundler.settings["gem.#{key}"]
    end

    def validate_ext_name
      return unless gem_name.index('-')

      Bundler.ui.error "You have specified a gem name which does not conform to the \n" \
                       "naming guidelines for C extensions. For more information, \n" \
                       "see the 'Extension Naming' section at the following URL:\n" \
                       "http://guides.rubygems.org/gems-with-extensions/\n"
      exit 1
    end

    def ask_and_set_test_framework
      test_framework = options[:test] || Bundler.settings["gem.test"]
      if test_framework.nil?
        result = Bundler.ui.ask("Would like to generate tests along with their gems? (rspec/minitest/false):")
        test_framework = result == "false" ? false : result
      end

      if Bundler.settings["gem.test"].nil?
        Bundler.settings.set_global("gem.test", test_framework)
      end

      return if test_framework == "false"
      test_framework
    end

  end
end
