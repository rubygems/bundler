require "spec_helper"
require "thread"

describe "fetching dependencies with a not available mirror", :realworld => true do
  let(:mirror) { @mirror_uri }
  let(:original) { @server_uri }

  before do
    require_rack
    setup_mirror
    setup_server
  end

  after do
    @server_thread.kill
  end

  context "with a specific fallback timeout" do
    before do
      global_config("BUNDLE_MIRROR__HTTP://127__0__0__1:#{@server_port}/__FALLBACK_TIMEOUT/" => "true",
                    "BUNDLE_MIRROR__HTTP://127__0__0__1:#{@server_port}/" => @mirror_uri)
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
  end

  context "with a global fallback timeout" do
    before do
      global_config("BUNDLE_MIRROR__ALL__FALLBACK_TIMEOUT/" => "1",
                    "BUNDLE_MIRROR__ALL" => @mirror_uri)
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
  end

  context "with a specific mirror without a fallback timeout" do
    before do
      global_config("BUNDLE_MIRROR__HTTP://127__0__0__1:#{@server_port}/" => @mirror_uri)
    end

    it "fails to install the gem with a timeout error" do
      gemfile <<-G
        source "#{original}"
        gem 'weakling'
      G

      bundle :install

      expect(out).to include("Fetching source index from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (2/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (3/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (4/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Could not fetch specs from #{@mirror_uri}")
    end
  end

  context "with a global mirror without a fallback timeout" do
    before do
      global_config("BUNDLE_MIRROR__ALL" => @mirror_uri)
    end

    it "fails to install the gem with a timeout error" do
      gemfile <<-G
        source "#{original}"
        gem 'weakling'
      G

      bundle :install

      expect(out).to include("Fetching source index from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (2/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (3/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Retrying fetcher due to error (4/4): Bundler::HTTPError Could not fetch specs from #{@mirror_uri}")
      expect(out).to include("Could not fetch specs from #{@mirror_uri}")
    end
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
