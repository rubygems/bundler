# Pull the
require File.expand_path("../../path.rb", __FILE__)
include Spec::Path

# Set up pretend http gem server with FakeWeb
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/fakeweb*/lib")].first}"
require 'fakeweb'

FakeWeb.allow_net_connect = false

files = [ 'quick/Marshal.4.8/rack-1.0.0.gemspec.rz',
          'gems/rack-1.0.0.gem' ]
files.each do |file|
  FakeWeb.register_uri(:get, "http://localgemserver.test/#{file}",
    :body => File.read("#{gem_repo1}/#{file}"))
end

FakeWeb.register_uri(:get, "http://localgemserver.test/api/v1/dependencies?gems=rack",
  :body => File.read(File.expand_path("../rack-1.0.0.marshal", __FILE__)))
