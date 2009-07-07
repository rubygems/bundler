$:.push File.join(File.dirname(__FILE__), '..', 'lib')
$:.push File.join(File.dirname(__FILE__), '..', 'gem_resolver', 'lib')
require "gem_resolver/builders"
require "bundler"
require "pp"

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
end