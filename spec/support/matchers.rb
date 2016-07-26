# frozen_string_literal: true
module Spec
  module Matchers
    MAJOR_DEPRECATION = /^\[DEPRECATED FOR 2\.0\]\s*/

    RSpec::Matchers.define :lack_errors do
      diffable
      match do |actual|
        actual.gsub(/#{MAJOR_DEPRECATION}.+[\n]?/, "") == ""
      end
    end

    RSpec::Matchers.define :eq_err do |expected|
      diffable
      match do |actual|
        actual.gsub(/#{MAJOR_DEPRECATION}.+[\n]?/, "") == expected
      end
    end

    RSpec::Matchers.define :have_major_deprecation do |expected|
      diffable
      match do |actual|
        actual.split(MAJOR_DEPRECATION).any? do |d|
          !d.empty? && values_match?(expected, d.strip)
        end
      end
    end

    RSpec::Matchers.define :have_dep do |*args|
      dep = Bundler::Dependency.new(*args)

      match do |actual|
        actual.length == 1 && actual.all? {|d| d == dep }
      end
    end

    RSpec::Matchers.define :have_gem do |*args|
      match do |actual|
        actual.length == args.length && actual.all? {|a| args.include?(a.full_name) }
      end
    end

    RSpec::Matchers.define :have_rubyopts do |*args|
      args = args.flatten
      args = args.first.split(/\s+/) if args.size == 1

      match do |actual|
        actual = actual.split(/\s+/) if actual.is_a?(String)
        args.all? {|arg| actual.include?(arg) } && actual.uniq.size == actual.size
      end
    end

    RSpec::Matchers.define :read_as do |file_contents|
      diffable
      match do |actual|
        if File.file?(actual)
          @actual = Bundler.read_file(actual)
          @actual == file_contents
        end
      end
    end

    def should_be_installed(*names)
      opts = names.last.is_a?(Hash) ? names.pop : {}
      source = opts.delete(:source)
      groups = Array(opts[:groups])
      groups << opts
      aggregate_failures "should be installed" do
        names.each do |name|
          name, version, platform = name.split(/\s+/)
          version_const = name == "bundler" ? "Bundler::VERSION" : Spec::Builders.constantize(name)
          run! "require '#{name}.rb'; puts #{version_const}", *groups
          expect(out).not_to be_empty, "#{name} is not installed"
          out.gsub!(/#{MAJOR_DEPRECATION}.*$/, "")
          actual_version, actual_platform = out.strip.split(/\s+/, 2)
          expect(Gem::Version.new(actual_version)).to eq(Gem::Version.new(version))
          expect(actual_platform).to eq(platform)
          next unless source
          source_const = "#{Spec::Builders.constantize(name)}_SOURCE"
          run! "require '#{name}/source'; puts #{source_const}", *groups
          out.gsub!(/#{MAJOR_DEPRECATION}.*$/, "")
          expect(out.strip).to eq(source),
            "Expected #{name} (#{version}) to be installed from `#{source}`, was actually from `#{out}`"
        end
      end
    end

    alias_method :should_be_available, :should_be_installed

    def should_not_be_installed(*names)
      opts = names.last.is_a?(Hash) ? names.pop : {}
      groups = Array(opts[:groups]) || []
      names.each do |name|
        name, version = name.split(/\s+/, 2)
        run <<-R, *(groups + [opts])
          begin
            require '#{name}'
            puts #{Spec::Builders.constantize(name)}
          rescue LoadError, NameError
            puts "WIN"
          end
        R
        if version.nil? || out == "WIN"
          expect(out).to eq("WIN")
        else
          expect(Gem::Version.new(out)).not_to eq(Gem::Version.new(version))
        end
      end
    end

    def plugin_should_be_installed(*names)
      names.each do |name|
        path = Bundler::Plugin.installed?(name)
        expect(path).to be_truthy
        expect(Pathname.new(path).join("plugins.rb")).to exist
      end
    end

    def plugin_should_not_be_installed(*names)
      names.each do |name|
        path = Bundler::Plugin.installed?(name)
        expect(path).to be_falsey
      end
    end

    def should_be_locked
      expect(bundled_app("Gemfile.lock")).to exist
    end

    def lockfile_should_be(expected)
      should_be_locked
      expect(bundled_app("Gemfile.lock")).to read_as(strip_whitespace(expected))
    end
  end
end
