require "spec_helper"
require "thread"

describe "fetching dependencies with a mirrored source", :rubygems => ">= 2.0" do
  let(:mirror) { "https://server.example.org" }
  let(:original) { "http://127.0.0.1:#{@port}" }

  before do
    setup_server
    bundle "config --local mirror.#{mirror} #{original}"
  end

  after { @t.kill }

  it "sets the 'X-Gemfile-Source' header and bundles successfully" do
    gemfile <<-G
      source "#{mirror}"
      gem 'weakling'
    G

    bundle :install

    expect(out).to include("Installing weakling")
    expect(out).to include("Bundle complete")
    should_be_installed "weakling 0.0.3"
  end

  private

  def setup_server
    # need to hack, so we can require rack
    old_gem_home = ENV["GEM_HOME"]
    ENV["GEM_HOME"] = Spec::Path.base_system_gems.to_s
    require "rack"
    ENV["GEM_HOME"] = old_gem_home

    @port = 21_459
    @port += 1 while TCPSocket.new("127.0.0.1", @port) rescue false
    @server_uri = "http://127.0.0.1:#{@port}"

    require File.expand_path("../../support/artifice/endpoint_mirror_source", __FILE__)

    @t = Thread.new {
      Rack::Server.start(:app       => EndpointMirrorSource,
                         :Host      => "0.0.0.0",
                         :Port      => @port,
                         :server    => "webrick",
                         :AccessLog => [])
    }.run

    wait_for_server(@port)
  end

  def wait_for_server(port, seconds = 15)
    tries = 0
    sleep 0.5
    TCPSocket.new("127.0.0.1", port)
  rescue => e
    raise(e) if tries > (seconds * 2)
    tries += 1
    retry
  end
end
