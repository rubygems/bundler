require File.expand_path("../../path.rb", __FILE__)
include Spec::Path

$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/fakeweb*/lib")].first}"
require 'fakeweb'

FakeWeb.allow_net_connect = false

FakeWeb.register_uri(:get, 'https://rubygems.org/api/v1/gems/foobar.yaml',
  :body => "---\nversion: 1.2.3")
