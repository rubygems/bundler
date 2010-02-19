# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bundler08}
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz", "Carl Lerche"]
  s.date = %q{2010-02-19}
  s.description = %q{An easy way to vendor gem dependencies}
  s.email = ["wycats@gmail.com", "clerche@engineyard.com"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/bundler08/bundle.rb", "lib/bundler08/cli.rb", "lib/bundler08/commands/bundle_command.rb", "lib/bundler08/commands/exec_command.rb", "lib/bundler08/dependency.rb", "lib/bundler08/dsl.rb", "lib/bundler08/environment.rb", "lib/bundler08/finder.rb", "lib/bundler08/gem_bundle.rb", "lib/bundler08/gem_ext.rb", "lib/bundler08/remote_specification.rb", "lib/bundler08/resolver.rb", "lib/bundler08/runtime.rb", "lib/bundler08/source.rb", "lib/bundler08/templates/app_script.erb", "lib/bundler08/templates/environment.erb", "lib/bundler08/templates/environment_picker.erb", "lib/bundler08/templates/Gemfile", "lib/bundler08.rb", "lib/rubygems_plugin.rb"]
  s.homepage = %q{http://github.com/wycats/bundler}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{An easy way to vendor gem dependencies}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
