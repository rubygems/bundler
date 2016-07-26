# frozen_string_literal: true
require "forwardable"
module Spec
  module Matchers
    extend RSpec::Matchers

    class Precondition
      include RSpec::Matchers::Composable
      extend Forwardable
      def_delegators :failing_matcher,
        :failure_message,
        :actual,
        :description,
        :diffable?,
        :does_not_match?,
        :expected,
        :failure_message_when_negated

      def initialize(matcher, preconditions)
        @matcher = with_matchers_cloned(matcher)
        @preconditions = with_matchers_cloned(preconditions)
      end

      def matches?(target, &blk)
        @failure_index = @preconditions.index {|pc| !pc.matches?(target, &blk) }
        !@failure_index && @matcher.matches?(target, &blk)
      end

      def expects_call_stack_jump?
        @matcher.expects_call_stack_jump? || @preconditions.any?(&:expects_call_stack_jump)
      end

      def supports_block_expectations?
        @matcher.supports_block_expectations? || @preconditions.any?(&:supports_block_expectations)
      end

      def failing_matcher
        @failure_index ? @preconditions[@failure_index] : @matcher
      end
    end

    def self.define_compound_matcher(matcher, preconditions, &declarations)
      raise "Must have preconditions to define a compound matcher" if preconditions.empty?
      define_method(matcher) do |*expected, &block_arg|
        Precondition.new(
          RSpec::Matchers::DSL::Matcher.new(matcher, declarations, self, *expected, &block_arg),
          preconditions
        )
      end
    end

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

    define_compound_matcher :read_as, [exist] do |file_contents|
      diffable
      match do |actual|
        @actual = Bundler.read_file(actual)
        values_match?(file_contents, @actual)
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
        expect(Bundler::Plugin).to be_installed(name)
        path = Bundler::Plugin.installed?(name)
        expect(File.join(path, "plugins.rb")).to exist
      end
    end

    def plugin_should_not_be_installed(*names)
      names.each do |name|
        expect(Bundler::Plugin).not_to be_installed(name)
      end
    end

    def should_be_locked
      expect(bundled_app("Gemfile.lock")).to exist
    end

    def lockfile_should_be(expected)
      expect(bundled_app("Gemfile.lock")).to read_as(strip_whitespace(expected))
    end
  end
end
