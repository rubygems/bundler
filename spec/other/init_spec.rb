require "spec_helper"

describe "bundle init" do
  it "generates a Gemfile" do
    bundle :init
    bundled_app("Gemfile").should exist
  end

  it "does not change existing Gemfiles" do
    gemfile <<-G
      gem "rails"
    G

    lambda {
      bundle :init
    }.should_not change { File.read(bundled_app("Gemfile")) }
  end

  it "should generate from an existing gemspec" do
    spec_file = tmp.join('test.gemspec')
    File.open(spec_file, 'w') do |file|
      file << <<-S
        Gem::Specification.new do |s|
        s.name = 'test'
        s.add_dependency 'rack', '= 1.0.1'
        s.add_development_dependency 'rspec', '1.2'
        end
      S
    end

    bundle :init, :gemspec => spec_file

    gemfile = bundled_app("Gemfile").read
    gemfile.should =~ /source :gemcutter/
    gemfile.scan(/gem "rack", "= 1.0.1"/).size.should eq(1)
    gemfile.scan(/gem "rspec", "= 1.2"/).size.should eq(1)
    gemfile.scan(/group :development/).size.should eq(1)
  end

end