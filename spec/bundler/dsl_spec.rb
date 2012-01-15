require 'spec_helper'

describe Bundler::Dsl do
  describe '#_normalize_options' do
    before do
      @rubygems = mock("rubygems")
      Bundler::Source::Rubygems.stub(:new){ @rubygems }
    end

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

  describe "syntax errors" do
    it "should raise a Bundler::GemfileError" do
      gemfile "gem 'foo', :path => /unquoted/string/syntax/error"
      lambda { Bundler::Dsl.evaluate(bundled_app("Gemfile"), nil, true) }.
        should raise_error(Bundler::GemfileError)
    end
  end
end
