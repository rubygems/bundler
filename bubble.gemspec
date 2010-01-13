# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bubble}
  s.version = "0.9.0.pre"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=
  s.authors = ["Carl Lerche", "Yehuda Katz"]
  s.date = %q{2010-01-13}
  s.default_executable = %q{bbl}
  s.email = ["carlhuda@engineyard.com"]
  s.executables = ["bbl"]
  s.files = ["bin/bbl", "lib/bubble/cli.rb", "lib/bubble/definition.rb", "lib/bubble/dependency.rb", "lib/bubble/dsl.rb", "lib/bubble/environment.rb", "lib/bubble/index.rb", "lib/bubble/installer.rb", "lib/bubble/remote_specification.rb", "lib/bubble/resolver.rb", "lib/bubble/rubygems.rb", "lib/bubble/source.rb", "lib/bubble/specification.rb", "lib/bubble/templates/Gemfile", "lib/bubble/vendor/thor/actions/create_file.rb", "lib/bubble/vendor/thor/actions/directory.rb", "lib/bubble/vendor/thor/actions/empty_directory.rb", "lib/bubble/vendor/thor/actions/file_manipulation.rb", "lib/bubble/vendor/thor/actions/inject_into_file.rb", "lib/bubble/vendor/thor/actions.rb", "lib/bubble/vendor/thor/base.rb", "lib/bubble/vendor/thor/core_ext/file_binary_read.rb", "lib/bubble/vendor/thor/core_ext/hash_with_indifferent_access.rb", "lib/bubble/vendor/thor/core_ext/ordered_hash.rb", "lib/bubble/vendor/thor/error.rb", "lib/bubble/vendor/thor/group.rb", "lib/bubble/vendor/thor/invocation.rb", "lib/bubble/vendor/thor/parser/argument.rb", "lib/bubble/vendor/thor/parser/arguments.rb", "lib/bubble/vendor/thor/parser/option.rb", "lib/bubble/vendor/thor/parser/options.rb", "lib/bubble/vendor/thor/parser.rb", "lib/bubble/vendor/thor/rake_compat.rb", "lib/bubble/vendor/thor/runner.rb", "lib/bubble/vendor/thor/shell/basic.rb", "lib/bubble/vendor/thor/shell/color.rb", "lib/bubble/vendor/thor/shell.rb", "lib/bubble/vendor/thor/task.rb", "lib/bubble/vendor/thor/util.rb", "lib/bubble/vendor/thor/version.rb", "lib/bubble/vendor/thor.rb", "lib/bubble.rb", "LICENSE", "README"]
  s.homepage = %q{http://github.com/carlhuda/bubble}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Bubbles are fun}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
