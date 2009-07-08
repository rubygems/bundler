require File.dirname(__FILE__) + '/spec_helper'

describe "The library itself" do

  it "has no malformed whitespace" do
    Dir.chdir(File.dirname(__FILE__) + '/..') do
      `git ls-files`.split("\n").each do |filename|
        next if filename =~ /\.gitmodules|fixtures/
        filename.should have_no_tab_characters
        filename.should have_no_extraneous_spaces
      end
    end
  end
end
