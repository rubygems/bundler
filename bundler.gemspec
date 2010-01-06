# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bundler}
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz", "Carl Lerche"]
  s.date = %q{2010-01-04}
  s.description = %q{An easy way to vendor gem dependencies}
  s.email = ["wycats@gmail.com", "clerche@engineyard.com"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/bundler/bundle.rb", "lib/bundler/cli.rb", "lib/bundler/commands/bundle_command.rb", "lib/bundler/commands/exec_command.rb", "lib/bundler/dependency.rb", "lib/bundler/dsl.rb", "lib/bundler/environment.rb", "lib/bundler/finder.rb", "lib/bundler/gem_bundle.rb", "lib/bundler/gem_ext.rb", "lib/bundler/remote_specification.rb", "lib/bundler/resolver.rb", "lib/bundler/runtime.rb", "lib/bundler/source.rb", "lib/bundler/templates/app_script.erb", "lib/bundler/templates/environment.erb", "lib/bundler/templates/environment_picker.erb", "lib/bundler.rb", "lib/rubygems_plugin.rb"]
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
