require 'spec_helper'

describe "bundle add" do
  before :each do
    gemfile
  end

  context 'when version number is set' do
    it 'adds gem with provided version' do
      bundle 'add foo 1.2.3'
      expect(bundled_app('Gemfile').read).to match(/gem 'foo', '~> 1.2'/)
    end
  end

  context 'when version number is not set' do
    it 'adds gem with last stable version' do
      bundle 'add foobar', fakeweb: 'rubygems_api'
      expect(bundled_app('Gemfile').read).to match(/gem 'foobar', '~> 1.2'/)
    end
  end
end
