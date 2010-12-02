module Spec
  module Matchers
    RSpec::Matchers.define :have_dep do |*args|
      dep = Bundler::Dependency.new(*args)

      match do |actual|
        actual.length == 1 && actual.all? { |d| d == dep }
      end
    end

    RSpec::Matchers.define :have_gem do |*args|
      match do |actual|
        actual.length == args.length && actual.all? { |a| args.include?(a.full_name) }
      end
    end

    RSpec::Matchers.define :have_rubyopts do |*args|
      args = args.flatten
      args = args.first.split(/\s+/) if args.size == 1

      #failure_message_for_should "Expected RUBYOPT to have options #{args.join(" ")}. It was #{ENV["RUBYOPT"]}"

      match do |actual|
        actual = actual.split(/\s+/) if actual.is_a?(String)
        args.all? {|arg| actual.include?(arg) } && actual.uniq.size == actual.size
      end
    end

    def parse_spec_set_output
      out_ary         = out.split(/\n/) # captures the output from spec_set's materialize method
      gem_specs_ary   = out_ary.grep(/spec_set_gemspec/)
      loaded_gemspecs = gem_specs_ary.collect do |gst|
        nv = gst[/\{\:spec_set_gemspec => (.*)\}/, 1]
        n = nv[/\{\:name => ['](\S*)['],/, 1] if nv
        v = nv[/\:version => ['](\S*)['],/, 1] if nv
        p = nv[/\:platform => ['](\S*)[']\}/, 1] if nv
        (n && v) ? {:name => n, :version => v, :platform => p} : nil
      end
      loaded_gemspecs.delete_if{ |gs| gs.nil? }
    end

    def check_gemspec_version_platform(gsh, opts, platform, version)
      check Gem::Version.new(gsh[:version]).should == Gem::Version.new(version) if opts[:check_version]
      gsh[:platform].should == platform if opts[:check_platform]
    end

    def gemspec_count(opts)
      ( opts[:gemspec_count] || 1 )
    end

    def check_gemspecs(name, version, platform, opts = {})
      loaded_gemspecs = parse_spec_set_output
      if loaded_gemspecs.size == gemspec_count(opts)
        loaded_gemspecs.each do |gsh|
          if gsh[:name] =~ /#{name}/
            check_gemspec_version_platform(gsh, opts, platform, version)
          end
        end
      else
        loaded_gemspecs.size.should == gemspec_count(opts) if loaded_gemspecs.size > 0
        check_gemspec_version_platform(loaded_gemspecs[0], opts, platform, version)
      end
    end

    def should_be_installed(*names)
      cmd = ""
      opts = names.last.is_a?(Hash) ? names.pop : {}
      groups = Array(opts[:groups])
      groups << opts
      names.each do |name|
        name, version, platform = name.split(/\s+/)
        version_const = name == 'bundler' ? 'Bundler::VERSION' : Spec::Builders.constantize(name)
        env = ""
        if opts[:install_path]
          name, env = File.join(opts[:install_path],name), "ENV['BUNDLE_INSTALL_PATH']='#{opts[:install_path]}'"
          cmd << " #{env};"
        end
        cmd << " require '#{name}';"
        cmd << " puts #{version_const}; "
        run cmd, *groups
        check_gemspecs(name, version, platform, opts)
      end
    end

    alias should_be_activated should_be_installed
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
        if version.nil? || out[/WIN/]
          opts[:check_version] = false
          out.should match(/WIN/)
        else
          check_gemspecs(name, version, platform, opts)
        end
      end
    end

    def should_be_locked
      bundled_app("Gemfile.lock").should exist
    end

    RSpec::Matchers.define :be_with_diff do |expected|
      spaces = expected[/\A\s+/, 0] || ""
      expected.gsub!(/^#{spaces}/, '')

      failure_message_for_should do |actual|
        "The lockfile did not match.\n=== Expected:\n" <<
          expected << "\n=== Got:\n" << actual << "\n===========\n"
      end

      match do |actual|
        expected == actual
      end
    end

    def lockfile_should_be(expected)
      lock = File.read(bundled_app("Gemfile.lock"))
      lock.should be_with_diff(expected)
    end
  end
end
