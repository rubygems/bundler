# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bundler}
  s.version = "0.9.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Carl Lerche", "Yehuda Katz", "Andr\303\251 Arko"]
  s.date = %q{2010-03-23}
  s.default_executable = %q{bundle}
  s.email = ["carlhuda@engineyard.com"]
  s.executables = ["bundle"]
  s.files = ["bin/bundle", "lib/bundler/cli.rb", "lib/bundler/definition.rb", "lib/bundler/dependency.rb", "lib/bundler/dsl.rb", "lib/bundler/environment.rb", "lib/bundler/index.rb", "lib/bundler/installer.rb", "lib/bundler/remote_specification.rb", "lib/bundler/resolver.rb", "lib/bundler/rubygems_ext.rb", "lib/bundler/runtime.rb", "lib/bundler/settings.rb", "lib/bundler/setup.rb", "lib/bundler/shared_helpers.rb", "lib/bundler/source.rb", "lib/bundler/spec_set.rb", "lib/bundler/specification.rb", "lib/bundler/templates/environment.erb", "lib/bundler/templates/Gemfile", "lib/bundler/ui.rb", "lib/bundler/vendor/thor/base.rb", "lib/bundler/vendor/thor/core_ext/file_binary_read.rb", "lib/bundler/vendor/thor/core_ext/hash_with_indifferent_access.rb", "lib/bundler/vendor/thor/core_ext/ordered_hash.rb", "lib/bundler/vendor/thor/error.rb", "lib/bundler/vendor/thor/invocation.rb", "lib/bundler/vendor/thor/parser/argument.rb", "lib/bundler/vendor/thor/parser/arguments.rb", "lib/bundler/vendor/thor/parser/option.rb", "lib/bundler/vendor/thor/parser/options.rb", "lib/bundler/vendor/thor/parser.rb", "lib/bundler/vendor/thor/shell/basic.rb", "lib/bundler/vendor/thor/shell/color.rb", "lib/bundler/vendor/thor/shell.rb", "lib/bundler/vendor/thor/task.rb", "lib/bundler/vendor/thor/util.rb", "lib/bundler/vendor/thor/version.rb", "lib/bundler/vendor/thor.rb", "lib/bundler.rb", "LICENSE", "README.md", "ROADMAP.md", "CHANGELOG.md"]
  s.homepage = %q{http://github.com/carlhuda/bundler}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Bundles are fun}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
