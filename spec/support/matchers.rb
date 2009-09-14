module Spec
  module Matchers
    def change
      simple_matcher("should change") do |given, matcher|
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

    def only_have_specs(*names)
      simple_matcher("only have spec") do |given, matcher|
        given_names = given.map{ |s| s.full_name }
        matcher.failure_message = "expected specs to only contain #{names.inspect} but got: #{given_names.inspect}"
        names.sort == given_names.sort
      end
    end

    alias only_have_spec only_have_specs

    def have_load_paths(root, gem_load_paths)
      flattened_paths = []

      if gem_load_paths.is_a?(Hash)
        gem_load_paths.each do |gem_name, paths|
          paths.each { |path| flattened_paths << File.join(root, "gems", gem_name, path) }
        end
      else
        gem_load_paths.each do |path|
          flattened_paths << File.join(root, path)
        end
      end

      simple_matcher("have load paths") do |given, matcher|
        actual = run_in_context("puts $:").split("\n")

        flattened_paths.all? do |path|
          matcher.failure_message = "expected environment load paths to contain '#{path}', but it was:\n  #{actual.join("\n  ")}"
          actual.include?(path)
        end
      end
    end

    alias have_load_path have_load_paths

    def include_cached_gems(*gems)
      simple_matcher("include cached gems") do |given, matcher|
        matcher.negative_failure_message = "Gems #{gems.join(", ")} were all cached"
        gems.all? do |name|
          matcher.failure_message = "Gem #{name} was not cached"
          File.exists?(File.join(given, "cache", "#{name}.gem"))
        end
      end
    end

    alias include_cached_gem include_cached_gems

    def include_installed_gems(*gems)
      simple_matcher("include installed gems") do |given, matcher|
        matcher.negative_failure_message = "Gems #{gems.join(", ")} were all installed"
        gems.all? do |name|
          matcher.failure_message = "Gem #{name} was not installed"
          File.exists?(File.join(given, "specifications", "#{name}.gemspec")) &&
          File.directory?(File.join(given, "gems", "#{name}"))
        end
      end
    end

    alias include_installed_gem include_installed_gems

    def have_cached_gems(*gems)
      simple_matcher("have cached gems") do |given, matcher|
        installed = Dir[File.join(given, "cache", "*.gem")]
        matcher.failure_message = "The following gems were cached:\n#{installed.join("\n")}\n\n" \
                                  "Expected:\n#{gems.join("\n")}"

        Dir[File.join(given, "cache", "*.gem")].length == gems.length &&
        gems.all? do |name|
          matcher.failure_message = "Gem #{name} was not cached"
          File.exists?(File.join(given, "cache", "#{name}.gem"))
        end
      end
    end

    alias have_cached_gem have_cached_gems

    def have_installed_gems(*gems)
      simple_matcher("have installed gems") do |given, matcher|
        Dir[File.join(given, "specifications", "*.gemspec")].length == gems.length &&
        Dir[File.join(given, "gems", "*")].length == gems.length &&
        gems.all? do |name|
          matcher.failure_message = "Gem #{name} was not installed"
          File.exists?(File.join(given, "specifications", "#{name}.gemspec")) &&
          File.directory?(File.join(given, "gems", "#{name}"))
        end
      end
    end

    alias have_installed_gem have_installed_gems

    def have_log_message(message)
      simple_matcher("have log message") do |given, matcher|
        given.rewind
        log = given.read
        matcher.failure_message = "Expected logger to contain:\n  #{message}\n\nBut it was:\n  #{log.gsub("\n", "\n  ")}"
        message = /^#{Regexp.escape(message)}$/m unless message.is_a?(Regexp)
        log =~ message
      end
    end
  end
end

Spec::Matchers.define :match_gems do |expected|
  match do |actual|
    @_messages = []
    @dump = {}

    if actual.nil?
      @_messages << "The result is nil"
      next
    end

    actual.each do |spec|
      unless spec.is_a?(Gem::Specification)
        @_messages << "#{gem_resolver_inspect(spec)} was expected to be a Gem::Specification, but got #{spec.class}"
        next
      end
      @dump[spec.name.to_s] ||= []
      @dump[spec.name.to_s] << spec.version.to_s
    end

    if @_messages.any?
      @_messages.unshift "The gems #{gem_resolver_inspect(actual)} were not structured as expected"
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

  failure_message_for_should do |actual, matcher|
    @_messages.join("\n")
  end
end
