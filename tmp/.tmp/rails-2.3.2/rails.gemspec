# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rails}
  s.version = "2.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.date = %q{2010-11-24}
  s.default_executable = %q{rails}
  s.executables = ["rails"]
  s.files = ["bin/rails"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{This is just a fake gem for testing}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<actionpack>, ["= 2.3.2"])
      s.add_runtime_dependency(%q<activerecord>, ["= 2.3.2"])
      s.add_runtime_dependency(%q<actionmailer>, ["= 2.3.2"])
      s.add_runtime_dependency(%q<activeresource>, ["= 2.3.2"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<actionpack>, ["= 2.3.2"])
      s.add_dependency(%q<activerecord>, ["= 2.3.2"])
      s.add_dependency(%q<actionmailer>, ["= 2.3.2"])
      s.add_dependency(%q<activeresource>, ["= 2.3.2"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<actionpack>, ["= 2.3.2"])
    s.add_dependency(%q<activerecord>, ["= 2.3.2"])
    s.add_dependency(%q<actionmailer>, ["= 2.3.2"])
    s.add_dependency(%q<activeresource>, ["= 2.3.2"])
  end
end
