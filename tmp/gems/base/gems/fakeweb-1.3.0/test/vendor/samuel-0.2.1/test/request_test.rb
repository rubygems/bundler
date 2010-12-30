require 'test_helper'

class RequestTest < Test::Unit::TestCase

  context "making an HTTP request" do
    setup    { setup_test_logger
               FakeWeb.clean_registry
               Samuel.reset_config }
    teardown { teardown_test_logger }

    context "to GET http://example.com/test, responding with a 200 in 53ms" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Benchmark.stubs(:realtime).yields.returns(0.053)
        open "http://example.com/test"
      end

      should_log_lines     1
      should_log_at_level  :info
      should_log_including "HTTP request"
      should_log_including "(53ms)"
      should_log_including "[200 OK]"
      should_log_including "GET http://example.com/test"
    end

    context "on a non-standard port" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com:8080/test", :status => [200, "OK"])
        open "http://example.com:8080/test"
      end

      should_log_including "GET http://example.com:8080/test"
    end

    context "with SSL" do
      setup do
        FakeWeb.register_uri(:get, "https://example.com/test", :status => [200, "OK"])
        open "https://example.com/test"
      end

      should_log_including "HTTP request"
      should_log_including "GET https://example.com/test"
    end

    context "with SSL on a non-standard port" do
      setup do
        FakeWeb.register_uri(:get, "https://example.com:80/test", :status => [200, "OK"])
        open "https://example.com:80/test"
      end

      should_log_including "HTTP request"
      should_log_including "GET https://example.com:80/test"
    end

    context "that raises" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :exception => Errno::ECONNREFUSED)
        begin
          Net::HTTP.start("example.com") { |http| http.get("/test") }
        rescue Errno::ECONNREFUSED => @exception
        end
      end

      should_log_at_level    :warn
      should_log_including   "HTTP request"
      should_log_including   "GET http://example.com/test"
      should_log_including   "Errno::ECONNREFUSED"
      should_log_including   %r|\d+ms|
      should_raise_exception Errno::ECONNREFUSED
    end

    context "that responds with a 500-level code" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [502, "Bad Gateway"])
        Net::HTTP.start("example.com") { |http| http.get("/test") }
      end

      should_log_at_level :warn
    end

    context "that responds with a 400-level code" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [404, "Not Found"])
        Net::HTTP.start("example.com") { |http| http.get("/test") }
      end

      should_log_at_level :warn
    end

    context "inside a configuration block with :label => 'Example'" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.with_config :label => "Example" do
          open "http://example.com/test"
        end
      end

      should_log_including "Example request"
      should_have_config_afterwards_including :labels => {"" => "HTTP"},
                                              :label  => nil
    end

    context "inside a configuration block with :filter_params" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test?password=secret&username=chrisk",
                             :status => [200, "OK"])
        @uri = "http://example.com/test?password=secret&username=chrisk"
      end

      context "=> :password" do
        setup { Samuel.with_config(:filtered_params => :password) { open @uri } }
        should_log_including "http://example.com/test?password=[FILTERED]&username=chrisk"
      end

      context "=> :as" do
        setup { Samuel.with_config(:filtered_params => :ass) { open @uri } }
        should_log_including "http://example.com/test?password=[FILTERED]&username=chrisk"
      end

      context "=> ['pass', 'name']" do
        setup { Samuel.with_config(:filtered_params => %w(pass name)) { open @uri } }
        should_log_including "http://example.com/test?password=[FILTERED]&username=[FILTERED]"
      end
    end

    context "with a global config including :label => 'Example'" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.config[:label] = "Example"
        open "http://example.com/test"
      end

      should_log_including "Example request"
      should_have_config_afterwards_including :labels => {"" => "HTTP"},
                                              :label  => "Example"
    end

    context "with a global config including :label => 'Example' but inside config block that changes it to 'Example 2'" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.config[:label] = "Example"
        Samuel.with_config(:label => "Example 2") { open "http://example.com/test" }
      end

      should_log_including "Example 2 request"
      should_have_config_afterwards_including :labels => {"" => "HTTP"},
                                              :label  => "Example"
    end

    context "inside a config block of :label => 'Example 2' nested inside a config block of :label => 'Example'" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.with_config :label => "Example" do
          Samuel.with_config :label => "Example 2" do
            open "http://example.com/test"
          end
        end
      end

      should_log_including "Example 2 request"
      should_have_config_afterwards_including :labels => {"" => "HTTP"},
                                              :label => nil
    end

    context "wth a global config including :labels => {'example.com' => 'Example'} but inside a config block of :label => 'Example 3' nested inside a config block of :label => 'Example 2'" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.config[:labels] = {'example.com' => 'Example'}
        Samuel.with_config :label => "Example 2" do
          Samuel.with_config :label => "Example 3" do
            open "http://example.com/test"
          end
        end
      end

      should_log_including "Example 3 request"
      should_have_config_afterwards_including :labels => {'example.com' => 'Example'},
                                              :label  => nil
    end

    context "with a global config including :labels => {'example.com' => 'Example API'}" do
      setup do
        FakeWeb.register_uri(:get, "http://example.com/test", :status => [200, "OK"])
        Samuel.config[:labels] = {'example.com' => 'Example API'}
        open "http://example.com/test"
      end

      should_log_including "Example API request"
    end

  end

end
