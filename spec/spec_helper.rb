$:.push File.join(File.dirname(__FILE__), '..', 'lib')
$:.push File.join(File.dirname(__FILE__), '..', 'gem_resolver', 'lib')
require "gem_resolver/builders"
require "bundler"
require "pathname"
require "pp"

module Spec
  module Matchers
    def change
      simple_matcher("change") do |given, matcher|
        matcher.failure_message = "Expected the block to change, but it didn't"
        matcher.negative_failure_message = "Expected the block not to change, but it did"
        retval = yield
        given.call
        retval != yield
      end
    end

    def be_cached_at(dir)
      simple_matcher("the bundle should be cached") do |given|
        given.each do |spec|
          Dir[File.join(dir, 'cache', "#{spec.name}*.gem")].should have(1).item
        end
      end
    end
  end

  module Helpers
    def this_file
      Pathname.new(File.expand_path(File.dirname(__FILE__)))
    end

    def tmp_dir
      this_file.join("tmp")
    end

    def cached(gem_name)
      File.join(tmp_dir, 'cache', "#{gem_name}.gem")
    end

    def fixtures1
      this_file.join("fixtures")
    end

    def fixtures2
      this_file.join("fixtures2")
    end

    def fixture(gem_name)
      this_file.join("fixtures", "gems", "#{gem_name}.gem")
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(tmp_dir, 'cache'))
    end
  end
end

Spec::Matchers.create :match_gems do |expected|
  match do |actual|
    @_messages = []
    @dump = {}

    if actual.nil?
      @_messages << "The result is nil"
      next
    end

    actual.each do |spec|
      unless spec.is_a?(Gem::Specification)
        @_messages << "#{spec.gem_resolver_inspect} was expected to be a Gem::Specification, but got #{spec.class}"
        next
      end
      @dump[spec.name.to_s] ||= []
      @dump[spec.name.to_s] << spec.version.to_s
    end

    if @_messages.any?
      @_messages.unshift "The gems #{actual.gem_resolver_inspect} were not structured as expected"
      next false
    end

    unless @dump == expected
      @_messages << "The source index was expected to have the gems:"
      @_messages << expected.to_a.sort.pretty_inspect
      @_messages << "but got:"
      @_messages << @dump.to_a.sort.pretty_inspect
      next false
    end
    true
  end

  failure_message_for_should do |actual|
    @_messages.join("\n")
  end
end

Spec::Runner.configure do |config|
  config.include GemResolver::Builders
  config.include Spec::Matchers
  config.include Spec::Helpers
end