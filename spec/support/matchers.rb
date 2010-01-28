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

    def should_be_installed(*names)
      names.each do |name|
        name, version = name.split(/\s+/)
        run "require '#{name}'; puts #{Spec::Builders.constantize(name)}"
        Gem::Version.new(out).should == Gem::Version.new(version)
      end
    end

    alias should_be_available should_be_installed

    def should_not_be_installed(*names)
      names.each do |name|
        name, version = name.split(/\s+/)
        run "require '#{name}'; puts #{Spec::Builders.constantize(name)}"
        Gem::Version.new(out).should_not == Gem::Version.new(version)
      end
    end
  end
end