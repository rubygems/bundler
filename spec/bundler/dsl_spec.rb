require 'spec_helper'

describe Bundler::Dsl do
  before do
    @rubygems = mock("rubygems")
    Bundler::Source::Rubygems.stub(:new){ @rubygems }
  end

  describe '#_normalize_options' do
    it "should convert :github to :git" do
      subject.gem("sparks", :github => "indirect/sparks")
      github_uri = "git://github.com/indirect/sparks.git"
      subject.dependencies.first.source.uri.should == github_uri
    end

    it "should convert 'rails' to 'rails/rails'" do
      subject.gem("rails", :github => "rails")
      github_uri = "git://github.com/rails/rails.git"
      subject.dependencies.first.source.uri.should == github_uri
    end
  end

  describe '#method_missing' do
    it 'should raise an error for unknown DSL methods' do
      dsl = Bundler::Dsl.new
      dsl.stub(:caller => ['Gemfile:3'])
      Bundler.should_receive(:read_file).with('Gemfile').and_return("source :rubygems\ngemspec\nunknown")

      error_msg = "The Gemfile doesn't support the method `unknown`.\nPlease check your Gemfile's syntax at line 3:\n\n  source :rubygems\n  gemspec\n  unknown\n"
      lambda { dsl.unknown }.should raise_error(Bundler::GemfileError, error_msg)
    end
  end

  describe "#eval_gemfile" do
    it "handles syntax errors with a useful message" do
      Bundler.should_receive(:read_file).with("Gemfile").and_return("}")
      lambda{ subject.eval_gemfile("Gemfile") }.
        should raise_error(Bundler::GemfileError, /Gemfile syntax error/)
    end
  end

end
