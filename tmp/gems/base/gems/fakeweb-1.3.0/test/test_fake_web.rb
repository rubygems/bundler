require 'test_helper'

class TestFakeWeb < Test::Unit::TestCase

  def test_register_uri
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => "example")
    assert FakeWeb.registered_uri?(:get, 'http://mock/test_example.txt')
  end

  def test_register_uri_with_wrong_number_of_arguments
    assert_raises ArgumentError do
      FakeWeb.register_uri("http://example.com")
    end
    assert_raises ArgumentError do
      FakeWeb.register_uri(:get, "http://example.com", "/example", :body => "example")
    end
  end

  def test_registered_uri_with_wrong_number_of_arguments
    assert_raises ArgumentError do
      FakeWeb.registered_uri?
    end
    assert_raises ArgumentError do
      FakeWeb.registered_uri?(:get, "http://example.com", "/example")
    end
  end

  def test_response_for_with_wrong_number_of_arguments
    assert_raises ArgumentError do
      FakeWeb.response_for
    end
    assert_raises ArgumentError do
      FakeWeb.response_for(:get, "http://example.com", "/example")
    end
  end

  def test_register_uri_without_domain_name
    assert_raises URI::InvalidURIError do
      FakeWeb.register_uri(:get, 'test_example2.txt', fixture_path("test_example.txt"))
    end
  end

  def test_register_uri_with_port_and_check_with_port
    FakeWeb.register_uri(:get, 'http://example.com:3000/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com:3000/')
  end

  def test_register_uri_with_port_and_check_without_port
    FakeWeb.register_uri(:get, 'http://example.com:3000/', :body => 'foo')
    assert !FakeWeb.registered_uri?(:get, 'http://example.com/')
  end

  def test_register_uri_with_default_port_for_http_and_check_without_port
    FakeWeb.register_uri(:get, 'http://example.com:80/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com/')
  end

  def test_register_uri_with_default_port_for_https_and_check_without_port
    FakeWeb.register_uri(:get, 'https://example.com:443/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'https://example.com/')
  end

  def test_register_uri_with_no_port_for_http_and_check_with_default_port
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com:80/')
  end

  def test_register_uri_with_no_port_for_https_and_check_with_default_port
    FakeWeb.register_uri(:get, 'https://example.com/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'https://example.com:443/')
  end

  def test_register_uri_with_no_port_for_https_and_check_with_443_on_http
    FakeWeb.register_uri(:get, 'https://example.com/', :body => 'foo')
    assert !FakeWeb.registered_uri?(:get, 'http://example.com:443/')
  end

  def test_register_uri_with_no_port_for_http_and_check_with_80_on_https
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'foo')
    assert !FakeWeb.registered_uri?(:get, 'https://example.com:80/')
  end

  def test_register_uri_for_any_method_explicitly
    FakeWeb.register_uri(:any, "http://example.com/rpc_endpoint", :body => "OK")
    assert FakeWeb.registered_uri?(:get, "http://example.com/rpc_endpoint")
    assert FakeWeb.registered_uri?(:post, "http://example.com/rpc_endpoint")
    assert FakeWeb.registered_uri?(:put, "http://example.com/rpc_endpoint")
    assert FakeWeb.registered_uri?(:delete, "http://example.com/rpc_endpoint")
    assert FakeWeb.registered_uri?(:any, "http://example.com/rpc_endpoint")
    capture_stderr do  # silence deprecation warning
      assert FakeWeb.registered_uri?("http://example.com/rpc_endpoint")
    end
  end

  def test_register_uri_for_get_method_only
    FakeWeb.register_uri(:get, "http://example.com/users", :body => "User list")
    assert FakeWeb.registered_uri?(:get, "http://example.com/users")
    assert !FakeWeb.registered_uri?(:post, "http://example.com/users")
    assert !FakeWeb.registered_uri?(:put, "http://example.com/users")
    assert !FakeWeb.registered_uri?(:delete, "http://example.com/users")
    assert !FakeWeb.registered_uri?(:any, "http://example.com/users")
    capture_stderr do  # silence deprecation warning
      assert !FakeWeb.registered_uri?("http://example.com/users")
    end
  end

  def test_clean_registry_affects_registered_uri
    FakeWeb.register_uri(:get, "http://example.com", :body => "registered")
    assert FakeWeb.registered_uri?(:get, "http://example.com")
    FakeWeb.clean_registry
    assert !FakeWeb.registered_uri?(:get, "http://example.com")
  end

  def test_clean_registry_affects_net_http_requests
    FakeWeb.register_uri(:get, "http://example.com", :body => "registered")
    response = Net::HTTP.start("example.com") { |query| query.get("/") }
    assert_equal "registered", response.body
    FakeWeb.clean_registry
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.start("example.com") { |query| query.get("/") }
    end
  end

  def test_response_for_with_registered_uri
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    assert_equal 'test example content', FakeWeb.response_for(:get, 'http://mock/test_example.txt').body
  end

  def test_response_for_with_unknown_uri
    assert_nil FakeWeb.response_for(:get, 'http://example.com/')
  end

  def test_response_for_with_put_method
    FakeWeb.register_uri(:put, "http://example.com", :body => "response")
    assert_equal 'response', FakeWeb.response_for(:put, "http://example.com").body
  end

  def test_response_for_with_any_method_explicitly
    FakeWeb.register_uri(:any, "http://example.com", :body => "response")
    assert_equal 'response', FakeWeb.response_for(:get, "http://example.com").body
    assert_equal 'response', FakeWeb.response_for(:any, "http://example.com").body
  end

  def test_content_for_registered_uri_with_port_and_request_with_port
    FakeWeb.register_uri(:get, 'http://example.com:3000/', :body => 'test example content')
    response = Net::HTTP.start('example.com', 3000) { |http| http.get('/') }
    assert_equal 'test example content', response.body
  end

  def test_content_for_registered_uri_with_default_port_for_http_and_request_without_port
    FakeWeb.register_uri(:get, 'http://example.com:80/', :body => 'test example content')
    response = Net::HTTP.start('example.com') { |http| http.get('/') }
    assert_equal 'test example content', response.body
  end

  def test_content_for_registered_uri_with_no_port_for_http_and_request_with_default_port
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'test example content')
    response = Net::HTTP.start('example.com', 80) { |http| http.get('/') }
    assert_equal 'test example content', response.body
  end

  def test_content_for_registered_uri_with_default_port_for_https_and_request_with_default_port
    FakeWeb.register_uri(:get, 'https://example.com:443/', :body => 'test example content')
    http = Net::HTTP.new('example.com', 443)
    http.use_ssl = true
    response = http.get('/')
    assert_equal 'test example content', response.body
  end

  def test_content_for_registered_uri_with_no_port_for_https_and_request_with_default_port
    FakeWeb.register_uri(:get, 'https://example.com/', :body => 'test example content')
    http = Net::HTTP.new('example.com', 443)
    http.use_ssl = true
    response = http.get('/')
    assert_equal 'test example content', response.body
  end

  def test_content_for_registered_uris_with_ports_on_same_domain_and_request_without_port
    FakeWeb.register_uri(:get, 'http://example.com:3000/', :body => 'port 3000')
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'port 80')
    response = Net::HTTP.start('example.com') { |http| http.get('/') }
    assert_equal 'port 80', response.body
  end

  def test_content_for_registered_uris_with_ports_on_same_domain_and_request_with_port
    FakeWeb.register_uri(:get, 'http://example.com:3000/', :body => 'port 3000')
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'port 80')
    response = Net::HTTP.start('example.com', 3000) { |http| http.get('/') }
    assert_equal 'port 3000', response.body
  end

  def test_content_for_registered_uri_with_get_method_only
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:get, "http://example.com/", :body => "test example content")
    http = Net::HTTP.new('example.com')
    assert_equal 'test example content', http.get('/').body
    assert_raises(FakeWeb::NetConnectNotAllowedError) { http.post('/', nil) }
    assert_raises(FakeWeb::NetConnectNotAllowedError) { http.put('/', nil) }
    assert_raises(FakeWeb::NetConnectNotAllowedError) { http.delete('/') }
  end

  def test_content_for_registered_uri_with_any_method_explicitly
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:any, "http://example.com/", :body => "test example content")
    http = Net::HTTP.new('example.com')
    assert_equal 'test example content', http.get('/').body
    assert_equal 'test example content', http.post('/', nil).body
    assert_equal 'test example content', http.put('/', nil).body
    assert_equal 'test example content', http.delete('/').body
  end

  def test_content_for_registered_uri_with_any_method_implicitly
    FakeWeb.allow_net_connect = false
    capture_stderr do  # silence deprecation warning
      FakeWeb.register_uri("http://example.com/", :body => "test example content")
    end

    http = Net::HTTP.new('example.com')
    assert_equal 'test example content', http.get('/').body
    assert_equal 'test example content', http.post('/', nil).body
    assert_equal 'test example content', http.put('/', nil).body
    assert_equal 'test example content', http.delete('/').body
  end

  def test_mock_request_with_block
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    response = Net::HTTP.start('mock') { |http| http.get('/test_example.txt') }
    assert_equal 'test example content', response.body
  end

  def test_request_with_registered_body_yields_the_response_body_to_a_request_block
    FakeWeb.register_uri(:get, "http://example.com", :body => "content")
    body = nil
    Net::HTTP.start("example.com") do |http|
      http.get("/") do |response_body|
        body = response_body
      end
    end
    assert_equal "content", body
  end

  def test_request_with_registered_response_yields_the_response_body_to_a_request_block
    fake_response = Net::HTTPOK.new('1.1', '200', 'OK')
    fake_response.instance_variable_set(:@body, "content")
    FakeWeb.register_uri(:get, 'http://example.com', :response => fake_response)
    body = nil
    Net::HTTP.start("example.com") do |http|
      http.get("/") do |response_body|
        body = response_body
      end
    end
    assert_equal "content", body
  end

  def test_mock_request_with_undocumented_full_uri_argument_style
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    response = Net::HTTP.start('mock') { |query| query.get('http://mock/test_example.txt') }
    assert_equal 'test example content', response.body
  end

  def test_mock_request_with_undocumented_full_uri_argument_style_and_query
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt?a=b', :body => 'test query content')
    response = Net::HTTP.start('mock') { |query| query.get('http://mock/test_example.txt?a=b') }
    assert_equal 'test query content', response.body
  end

  def test_mock_post
    FakeWeb.register_uri(:post, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    response = Net::HTTP.start('mock') { |query| query.post('/test_example.txt', '') }
    assert_equal 'test example content', response.body
  end

  def test_mock_post_with_string_as_registered_uri
    FakeWeb.register_uri(:post, 'http://mock/test_string.txt', :body => 'foo')
    response = Net::HTTP.start('mock') { |query| query.post('/test_string.txt', '') }
    assert_equal 'foo', response.body
  end

  def test_mock_post_with_body_sets_the_request_body
    FakeWeb.register_uri(:post, "http://example.com/posts", :status => [201, "Created"])
    http = Net::HTTP.new("example.com")
    request = Net::HTTP::Post.new("/posts")
    http.request(request, "title=Test")
    assert_equal "title=Test", request.body
    assert_equal 10, request.content_length
  end

  def test_mock_post_with_body_using_other_syntax_sets_the_request_body
    FakeWeb.register_uri(:post, "http://example.com/posts", :status => [201, "Created"])
    http = Net::HTTP.new("example.com")
    request = Net::HTTP::Post.new("/posts")
    request.body = "title=Test"
    http.request(request)
    assert_equal "title=Test", request.body
    assert_equal 10, request.content_length
  end

  def test_real_post_with_body_sets_the_request_body
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request :method => "POST",
      :path => "/posts", :request_body => "title=Test"
    http = Net::HTTP.new("images.apple.com")
    request = Net::HTTP::Post.new("/posts")
    request["Content-Type"] = "application/x-www-form-urlencoded"
    http.request(request, "title=Test")
    assert_equal "title=Test", request.body
    assert_equal 10, request.content_length
  end

  def test_mock_get_with_request_as_registered_uri
    fake_response = Net::HTTPOK.new('1.1', '200', 'OK')
    FakeWeb.register_uri(:get, 'http://mock/test_response', :response => fake_response)
    response = Net::HTTP.start('mock') { |query| query.get('/test_response') }
    assert_equal fake_response, response
  end

  def test_mock_get_with_request_from_file_as_registered_uri
    FakeWeb.register_uri(:get, 'http://www.google.com/', :response => fixture_path("google_response_without_transfer_encoding"))
    response = Net::HTTP.start('www.google.com') { |query| query.get('/') }
    assert_equal '200', response.code
    assert response.body.include?('<title>Google</title>')
  end

  def test_mock_post_with_request_from_file_as_registered_uri
    FakeWeb.register_uri(:post, 'http://www.google.com/', :response => fixture_path("google_response_without_transfer_encoding"))
    response = Net::HTTP.start('www.google.com') { |query| query.post('/', '') }
    assert_equal "200", response.code
    assert response.body.include?('<title>Google</title>')
  end

  def test_proxy_request
    FakeWeb.register_uri(:get, 'http://www.example.com/', :body => "hello world")
    FakeWeb.register_uri(:get, 'http://your.proxy.host/', :body => "lala")

    response = nil
    Net::HTTP::Proxy('your.proxy.host', 8080).start('www.example.com') do |http|
      response = http.get('/')
    end
    assert_equal "hello world", response.body
  end

  def test_https_request
    FakeWeb.register_uri(:get, 'https://www.example.com/', :body => "Hello World")
    http = Net::HTTP.new('www.example.com', 443)
    http.use_ssl = true
    response = http.get('/')
    assert_equal "Hello World", response.body
  end

  def test_register_unimplemented_response
    FakeWeb.register_uri(:get, 'http://mock/unimplemented', :response => 1)
    assert_raises StandardError do
      Net::HTTP.start('mock') { |q| q.get('/unimplemented') }
    end
  end

  def test_specifying_nil_for_body
    FakeWeb.register_uri(:head, "http://example.com", :body => nil)
    response = Net::HTTP.start("example.com") { |query| query.head("/") }
    assert_equal "", response.body
  end

  def test_real_http_request
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request

    resp = nil
    Net::HTTP.start('images.apple.com') do |query|
      resp = query.get('/main/rss/hotnews/hotnews.rss')
    end
    assert resp.body.include?('Apple')
    assert resp.body.include?('News')
  end

  def test_real_http_request_with_undocumented_full_uri_argument_style
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request(:path => 'http://images.apple.com/main/rss/hotnews/hotnews.rss')

    resp = nil
    Net::HTTP.start('images.apple.com') do |query|
      resp = query.get('http://images.apple.com/main/rss/hotnews/hotnews.rss')
    end
    assert resp.body.include?('Apple')
    assert resp.body.include?('News')
  end

  def test_real_https_request
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request(:port => 443)

    http = Net::HTTP.new('images.apple.com', 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # silence certificate warning
    response = http.get('/main/rss/hotnews/hotnews.rss')
    assert response.body.include?('Apple')
    assert response.body.include?('News')
  end

  def test_real_request_on_same_domain_as_mock
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request

    FakeWeb.register_uri(:get, 'http://images.apple.com/test_string.txt', :body => 'foo')

    resp = nil
    Net::HTTP.start('images.apple.com') do |query|
      resp = query.get('/main/rss/hotnews/hotnews.rss')
    end
    assert resp.body.include?('Apple')
    assert resp.body.include?('News')
  end

  def test_mock_request_on_real_domain
    FakeWeb.register_uri(:get, 'http://images.apple.com/test_string.txt', :body => 'foo')
    resp = nil
    Net::HTTP.start('images.apple.com') do |query|
      resp = query.get('/test_string.txt')
    end
    assert_equal 'foo', resp.body
  end

  def test_mock_post_that_raises_exception
    FakeWeb.register_uri(:post, 'http://mock/raising_exception.txt', :exception => StandardError)
    assert_raises(StandardError) do
      Net::HTTP.start('mock') do |query|
        query.post('/raising_exception.txt', 'some data')
      end
    end
  end

  def test_mock_post_that_raises_an_http_error
    FakeWeb.register_uri(:post, 'http://mock/raising_exception.txt', :exception => Net::HTTPError)
    assert_raises(Net::HTTPError) do
      Net::HTTP.start('mock') do |query|
        query.post('/raising_exception.txt', '')
      end
    end
  end

  def test_raising_an_exception_that_requires_an_argument_to_instantiate
    FakeWeb.register_uri(:get, "http://example.com/timeout.txt", :exception => Timeout::Error)
    assert_raises(Timeout::Error) do
      Net::HTTP.get(URI.parse("http://example.com/timeout.txt"))
    end
  end

  def test_mock_instance_syntax
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    response = nil
    uri = URI.parse('http://mock/test_example.txt')
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.start do
      http.get(uri.path)
    end

    assert_equal 'test example content', response.body
  end

  def test_mock_via_nil_proxy
    response = nil
    proxy_address = nil
    proxy_port = nil
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => fixture_path("test_example.txt"))
    uri = URI.parse('http://mock/test_example.txt')
    http = Net::HTTP::Proxy(proxy_address, proxy_port).new(
              uri.host, (uri.port or 80))
    response = http.start do
      http.get(uri.path)
    end

    assert_equal 'test example content', response.body
  end

  def test_response_type
    FakeWeb.register_uri(:get, 'http://mock/test_example.txt', :body => "test")
    response = Net::HTTP.start('mock') { |http| http.get('/test_example.txt') }
    assert_kind_of Net::HTTPSuccess, response
  end

  def test_mock_request_that_raises_an_http_error_with_a_specific_status
    FakeWeb.register_uri(:get, 'http://mock/raising_exception.txt', :exception => Net::HTTPError, :status => ['404', 'Not Found'])
    exception = assert_raises(Net::HTTPError) do
      Net::HTTP.start('mock') { |http| http.get('/raising_exception.txt') }
    end
    assert_equal '404', exception.response.code
    assert_equal 'Not Found', exception.response.msg
  end

  def test_mock_rotate_responses
    FakeWeb.register_uri(:get, 'http://mock/multiple_test_example.txt',
                         [ {:body => fixture_path("test_example.txt"), :times => 2},
                           {:body => "thrice", :times => 3},
                           {:body => "ever_more"} ])

    uri = URI.parse('http://mock/multiple_test_example.txt')
    2.times { assert_equal 'test example content', Net::HTTP.get(uri) }
    3.times { assert_equal 'thrice',               Net::HTTP.get(uri) }
    4.times { assert_equal 'ever_more',            Net::HTTP.get(uri) }
  end

  def test_mock_request_using_response_with_transfer_encoding_header_has_valid_transfer_encoding_header
    FakeWeb.register_uri(:get, 'http://www.google.com/', :response => fixture_path("google_response_with_transfer_encoding"))
    response = Net::HTTP.start('www.google.com') { |query| query.get('/') }
    assert_not_nil response['transfer-encoding']
    assert response['transfer-encoding'] == 'chunked'
  end

  def test_mock_request_using_response_without_transfer_encoding_header_does_not_have_a_transfer_encoding_header
    FakeWeb.register_uri(:get, 'http://www.google.com/', :response => fixture_path("google_response_without_transfer_encoding"))
    response = nil
    response = Net::HTTP.start('www.google.com') { |query| query.get('/') }
    assert !response.key?('transfer-encoding')
  end

  def test_mock_request_using_response_from_curl_has_original_transfer_encoding_header
    FakeWeb.register_uri(:get, 'http://www.google.com/', :response => fixture_path("google_response_from_curl"))
    response = Net::HTTP.start('www.google.com') { |query| query.get('/') }
    assert_not_nil response['transfer-encoding']
    assert response['transfer-encoding'] == 'chunked'
  end

  def test_txt_file_should_have_three_lines
    FakeWeb.register_uri(:get, 'http://www.google.com/', :body => fixture_path("test_txt_file"))
    response = Net::HTTP.start('www.google.com') { |query| query.get('/') }
    assert response.body.split(/\n/).size == 3, "response has #{response.body.split(/\n/).size} lines should have 3"
  end

  def test_requiring_fakeweb_instead_of_fake_web
    require "fakeweb"
  end

  def test_registering_with_string_containing_null_byte
    # Regression test for File.exists? raising an ArgumentError ("string
    # contains null byte") since :response first tries to find by filename.
    # The string should be treated as a response body, instead, and an
    # EOFError is raised when the byte is encountered.
    FakeWeb.register_uri(:get, "http://example.com", :response => "test\0test")
    assert_raise EOFError do
      Net::HTTP.get(URI.parse("http://example.com"))
    end

    FakeWeb.register_uri(:get, "http://example.com", :body => "test\0test")
    body = Net::HTTP.get(URI.parse("http://example.com"))
    assert_equal "test\0test", body
  end

  def test_registering_with_string_that_is_a_directory_name
    # Similar to above, but for Errno::EISDIR being raised since File.exists?
    # returns true for directories
    FakeWeb.register_uri(:get, "http://example.com", :response => File.dirname(__FILE__))
    assert_raise EOFError do
      body = Net::HTTP.get(URI.parse("http://example.com"))
    end

    FakeWeb.register_uri(:get, "http://example.com", :body => File.dirname(__FILE__))
    body = Net::HTTP.get(URI.parse("http://example.com"))
    assert_equal File.dirname(__FILE__), body
  end

  def test_registering_with_a_body_pointing_to_a_pathname
    path = Pathname.new(fixture_path("test_example.txt"))
    FakeWeb.register_uri(:get, "http://example.com", :body => path)
    response = Net::HTTP.start("example.com") { |http| http.get("/") }
    assert_equal "test example content", response.body
  end

  def test_registering_with_a_response_pointing_to_a_pathname
    path = Pathname.new(fixture_path("google_response_without_transfer_encoding"))
    FakeWeb.register_uri(:get, "http://google.com", :response => path)
    response = Net::HTTP.start("google.com") { |http| http.get("/") }
    assert response.body.include?("<title>Google</title>")
  end

  def test_http_version_from_string_response
    FakeWeb.register_uri(:get, "http://example.com", :body => "example")
    response = Net::HTTP.start("example.com") { |http| http.get("/") }
    assert_equal "1.0", response.http_version
  end

  def test_http_version_from_file_response
    FakeWeb.register_uri(:get, "http://example.com", :body => fixture_path("test_example.txt"))
    response = Net::HTTP.start("example.com") { |http| http.get("/") }
    assert_equal "1.0", response.http_version
  end

  def test_version
    assert_equal "1.3.0", FakeWeb::VERSION
  end

end
