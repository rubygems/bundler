require 'spec_helper'

describe 'bundle install with a github block' do
  it 'installs multiple gems from a single github user' do
    gemfile <<-G
      github 'datamapper' do
        gem 'dm-core', '~> 1.3.0.beta'
        gem 'dm-types', '~> 1.3.0.beta'
      end
    G
    bundle "install"
    should_be_installed 'dm-core'
    should_be_installed 'dm-types'
  end

  it 'allows us to pass through a branch' do
    gemfile <<-G
      github 'datamapper' do
        gem 'dm-core', :branch => 'foo'
      end
    G
    should_be_installed 'dm-core'
  end
end
