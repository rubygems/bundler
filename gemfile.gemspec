# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gemfile}
  s.version = "0.9.0.pre"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=
  s.authors = ["Carl Lerche", "Yehuda Katz"]
  s.date = %q{2010-01-25}
  s.default_executable = %q{gemfile}
  s.email = ["carlhuda@engineyard.com"]
  s.executables = ["gemfile"]
  s.files = ["bin/gemfile", "lib/gemfile", "lib/gemfile/cli.rb", "lib/gemfile/definition.rb", "lib/gemfile/dependency.rb", "lib/gemfile/dsl.rb", "lib/gemfile/environment.rb", "lib/gemfile/index.rb", "lib/gemfile/installer.rb", "lib/gemfile/remote_specification.rb", "lib/gemfile/resolver.rb", "lib/gemfile/rubygems.rb", "lib/gemfile/source.rb", "lib/gemfile/specification.rb", "lib/gemfile/templates", "lib/gemfile/templates/environment.erb", "lib/gemfile/templates/Gemfile", "lib/gemfile/vendor", "lib/gemfile/vendor/thor", "lib/gemfile/vendor/thor/actions", "lib/gemfile/vendor/thor/actions/create_file.rb", "lib/gemfile/vendor/thor/actions/directory.rb", "lib/gemfile/vendor/thor/actions/empty_directory.rb", "lib/gemfile/vendor/thor/actions/file_manipulation.rb", "lib/gemfile/vendor/thor/actions/inject_into_file.rb", "lib/gemfile/vendor/thor/actions.rb", "lib/gemfile/vendor/thor/base.rb", "lib/gemfile/vendor/thor/core_ext", "lib/gemfile/vendor/thor/core_ext/file_binary_read.rb", "lib/gemfile/vendor/thor/core_ext/hash_with_indifferent_access.rb", "lib/gemfile/vendor/thor/core_ext/ordered_hash.rb", "lib/gemfile/vendor/thor/error.rb", "lib/gemfile/vendor/thor/group.rb", "lib/gemfile/vendor/thor/invocation.rb", "lib/gemfile/vendor/thor/parser", "lib/gemfile/vendor/thor/parser/argument.rb", "lib/gemfile/vendor/thor/parser/arguments.rb", "lib/gemfile/vendor/thor/parser/option.rb", "lib/gemfile/vendor/thor/parser/options.rb", "lib/gemfile/vendor/thor/parser.rb", "lib/gemfile/vendor/thor/rake_compat.rb", "lib/gemfile/vendor/thor/runner.rb", "lib/gemfile/vendor/thor/shell", "lib/gemfile/vendor/thor/shell/basic.rb", "lib/gemfile/vendor/thor/shell/color.rb", "lib/gemfile/vendor/thor/shell.rb", "lib/gemfile/vendor/thor/task.rb", "lib/gemfile/vendor/thor/util.rb", "lib/gemfile/vendor/thor/version.rb", "lib/gemfile/vendor/thor.rb", "lib/gemfile.rb", "LICENSE", "README"]
  s.homepage = %q{http://github.com/carlhuda/gemfile}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Gemfiles are fun}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
