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
      gem_load_paths.each do |gem_name, paths|
        paths.each { |path| flattened_paths << File.join(root, "gems", gem_name, path) }
      end

      simple_matcher("have load paths") do |given, matcher|
        actual = `ruby -r#{given} -e 'puts $:'`.split("\n")

        flattened_paths.all? do |path|
          matcher.failure_message = "expected environment load paths to contain '#{path}', but it was:\n  #{actual.join("\n  ")}"
          actual.include?(path)
        end
      end
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

  failure_message_for_should do |actual|
    @_messages.join("\n")
  end
end

Spec::Matchers.create :have_no_tab_characters do
  match do |filename|
    @failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      @failing_lines << number + 1 if line =~ /\t/
    end
    @failing_lines.empty?
  end

  failure_message_for_should do |filename|
    "The file #{filename} has tab characters on lines #{@failing_lines.join(', ')}"
  end
end

Spec::Matchers.create :have_no_extraneous_spaces do
  match do |filename|
    @failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      next if line =~ /^\s+#.*\s+\n$/
      @failing_lines << number + 1 if line =~ /\s+\n$/
    end
    @failing_lines.empty?
  end

  failure_message_for_should do |filename|
    "The file #{filename} has spaces on the EOL on lines #{@failing_lines.join(', ')}"
  end
end