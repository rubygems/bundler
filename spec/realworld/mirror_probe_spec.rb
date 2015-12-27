require "spec_helper"
require "thread"

describe "fetching dependencies with a not available mirror" do
  let(:mirror) { @mirror_uri }
  let(:original) { @server_uri }

  before do
    require_rack
    setup_mirror
    setup_server
    global_config("BUNDLE_MIRROR__HTTP://127__0__0__1:#{@server_port}/__FALLBACK_TIMEOUT/" => "true",
                  "BUNDLE_MIRROR__HTTP://127__0__0__1:#{@server_port}/" => @mirror_uri)
  end

  after do
    @server_thread.kill
  end


  it "install a gem using the original uri when the mirror is not responding" do
    gemfile <<-G
      source "#{original}"
      gem 'weakling'
    G

    bundle :install

    expect(out).to include("Installing weakling")
    expect(out).to include("Bundle complete")
    should_be_installed "weakling 0.0.3"
  end

  def setup_server
    @server_port = find_unused_port
    @server_host = "127.0.0.1"
    @server_uri = "http://#{@server_host}:#{@server_port}"

    require File.expand_path("../../support/artifice/endpoint", __FILE__)

    @server_thread = Thread.new do
      Rack::Server.start(:app       => Endpoint,
                         :Host      => @server_host,
                         :Port      => @server_port,
                         :server    => "webrick",
                         :AccessLog => [])
    end.run

    wait_for_server(@server_host, @server_port)
  end

  def setup_mirror
    @mirror_port = find_unused_port
    @mirror_host = "127.0.0.1"
    @mirror_uri = "http://#{@mirror_host}:#{@mirror_port}"
  end
end
