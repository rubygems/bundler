module Spec
  module Matchers
    def have_dep(*args)
      simple_matcher "have dependency" do |given, matcher|
        dep = Bundler::Dependency.new(*args)

        # given.length == args.length / 2
        given.length == 1 && given.all? { |d| d == dep }
      end
    end

    def have_gem(*args)
      simple_matcher "have gem" do |given, matcher|
        given.length == args.length && given.all? { |g| args.include?(g.full_name) }
      end
    end

    def have_rubyopts(*args)
      args = args.flatten
      args = args.first.split(/\s+/) if args.size == 1

      simple_matcher "have options #{args.join(' ')}" do |actual|
        actual = actual.split(/\s+/) if actual.is_a?(String)
        args.all? {|arg| actual.include?(arg) } && actual.uniq.size == actual.size
      end
    end

    def should_be_installed(*names)
      opts = names.last.is_a?(Hash) ? names.pop : {}
      groups = Array(opts[:groups])
      groups << opts
      names.each do |name|
        name, version, platform = name.split(/\s+/)
        version_const = name == 'bundler' ? 'Bundler::VERSION' : Spec::Builders.constantize(name)
        run "require '#{name}.rb'; puts #{version_const}", *groups
        actual_version, actual_platform = out.split(/\s+/)
        Gem::Version.new(actual_version).should == Gem::Version.new(version)
        actual_platform.should == platform
      end
    end

    alias should_be_available should_be_installed

    def should_not_be_installed(*names)
      opts = names.last.is_a?(Hash) ? names.pop : {}
      groups = Array(opts[:groups]) || []
      names.each do |name|
        name, version = name.split(/\s+/)
        run <<-R, *(groups + [opts])
          begin
            require '#{name}'
            puts #{Spec::Builders.constantize(name)}
          rescue LoadError, NameError
            puts "WIN"
          end
        R
        if version.nil? || out == "WIN"
          out.should == "WIN"
        else
          Gem::Version.new(out).should_not == Gem::Version.new(version)
        end
      end
    end

    def should_be_locked
      bundled_app("Gemfile.lock").should exist
    end
  end
end