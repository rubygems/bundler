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
    
    it "should work with maven as an option" do
      subject.gem("mvn:commons-lang:commons-lang","2.6.1",:mvn=>"default")
      source = subject.dependencies.first.source
      puts "SOURCE=#{source}"
      puts "SPECS = #{source.specs.inspect}"
    end
    
    it "should work with maven as a block" do
      subject.mvn("default") do
        subject.gem("mvn:commons-lang:commons-lang","2.6.1")
      end
      source = subject.dependencies.first.source
      puts "SOURCE=#{source}"
      puts "SPECS = #{source.specs.inspect}"      
    end
  end
end
