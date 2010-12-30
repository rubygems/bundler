require 'test_helper'

class TestFakeWebAllowNetConnect < Test::Unit::TestCase
  def test_unregistered_requests_are_passed_through_when_allow_net_connect_is_true
    FakeWeb.allow_net_connect = true
    setup_expectations_for_real_apple_hot_news_request
    Net::HTTP.get(URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss"))
  end

  def test_raises_for_unregistered_requests_when_allow_net_connect_is_false
    FakeWeb.allow_net_connect = false
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com/"))
    end
  end

  def test_unregistered_requests_are_passed_through_when_allow_net_connect_is_the_same_string
    FakeWeb.allow_net_connect = "http://images.apple.com/main/rss/hotnews/hotnews.rss"
    setup_expectations_for_real_apple_hot_news_request
    Net::HTTP.get(URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss"))
  end

  def test_unregistered_requests_are_passed_through_when_allow_net_connect_is_the_same_string_with_default_port
    FakeWeb.allow_net_connect = "http://images.apple.com:80/main/rss/hotnews/hotnews.rss"
    setup_expectations_for_real_apple_hot_news_request
    Net::HTTP.get(URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss"))
  end

  def test_unregistered_requests_are_passed_through_when_allow_net_connect_is_the_same_uri
    FakeWeb.allow_net_connect = URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss")
    setup_expectations_for_real_apple_hot_news_request
    Net::HTTP.get(URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss"))
  end

  def test_unregistered_requests_are_passed_through_when_allow_net_connect_is_a_matching_regexp
    FakeWeb.allow_net_connect = %r[^http://images\.apple\.com]
    setup_expectations_for_real_apple_hot_news_request
    Net::HTTP.get(URI.parse("http://images.apple.com/main/rss/hotnews/hotnews.rss"))
  end

  def test_raises_for_unregistered_requests_when_allow_net_connect_is_a_different_string
    FakeWeb.allow_net_connect = "http://example.com"
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com/path"))
    end
  end

  def test_raises_for_unregistered_requests_when_allow_net_connect_is_a_different_uri
    FakeWeb.allow_net_connect = URI.parse("http://example.com")
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com/path"))
    end
  end

  def test_raises_for_unregistered_requests_when_allow_net_connect_is_a_non_matching_regexp
    FakeWeb.allow_net_connect = %r[example\.net]
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com"))
    end
  end

  def test_changing_allow_net_connect_from_string_to_false_corretly_removes_whitelist
    FakeWeb.allow_net_connect = "http://example.com"
    FakeWeb.allow_net_connect = false
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com"))
    end
  end

  def test_changing_allow_net_connect_from_true_to_string_corretly_limits_connections
    FakeWeb.allow_net_connect = true
    FakeWeb.allow_net_connect = "http://example.com"
    assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.net"))
    end
  end

  def test_exception_message_includes_unregistered_request_method_and_uri_but_no_default_port
    FakeWeb.allow_net_connect = false
    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.get(URI.parse("http://example.com/"))
    end
    assert exception.message.include?("GET http://example.com/")

    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      http = Net::HTTP.new("example.com", 443)
      http.use_ssl = true
      http.get("/")
    end
    assert exception.message.include?("GET https://example.com/")
  end

  def test_exception_message_includes_unregistered_request_port_when_not_default
    FakeWeb.allow_net_connect = false
    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.start("example.com", 8000) { |http| http.get("/") }
    end
    assert exception.message.include?("GET http://example.com:8000/")

    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      http = Net::HTTP.new("example.com", 4433)
      http.use_ssl = true
      http.get("/")
    end
    assert exception.message.include?("GET https://example.com:4433/")
  end

  def test_exception_message_includes_unregistered_request_port_when_not_default_with_path
    FakeWeb.allow_net_connect = false
    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      Net::HTTP.start("example.com", 8000) { |http| http.get("/test") }
    end
    assert exception.message.include?("GET http://example.com:8000/test")

    exception = assert_raise FakeWeb::NetConnectNotAllowedError do
      http = Net::HTTP.new("example.com", 4433)
      http.use_ssl = true
      http.get("/test")
    end
    assert exception.message.include?("GET https://example.com:4433/test")
  end

  def test_question_mark_method_returns_true_after_setting_allow_net_connect_to_true
    FakeWeb.allow_net_connect = true
    assert FakeWeb.allow_net_connect?
  end

  def test_question_mark_method_returns_false_after_setting_allow_net_connect_to_false
    FakeWeb.allow_net_connect = false
    assert !FakeWeb.allow_net_connect?
  end

  def test_question_mark_method_raises_with_no_argument_when_allow_net_connect_is_a_whitelist
    FakeWeb.allow_net_connect = "http://example.com"
    exception = assert_raise ArgumentError do
      FakeWeb.allow_net_connect?
    end
    assert_equal "You must supply a URI to test", exception.message
  end

  def test_question_mark_method_returns_true_when_argument_is_same_uri_as_allow_net_connect_string
    FakeWeb.allow_net_connect = "http://example.com"
    assert FakeWeb.allow_net_connect?("http://example.com/")
  end

  def test_question_mark_method_returns_true_when_argument_matches_allow_net_connect_regexp
    FakeWeb.allow_net_connect = %r[^https?://example.com/]
    assert FakeWeb.allow_net_connect?("http://example.com/path")
    assert FakeWeb.allow_net_connect?("https://example.com:443/")
  end

  def test_question_mark_method_returns_false_when_argument_does_not_match_allow_net_connect_regexp
    FakeWeb.allow_net_connect = %r[^http://example.com/]
    assert !FakeWeb.allow_net_connect?("http://example.com:8080")
  end
end


class TestFakeWebAllowNetConnectWithCleanState < Test::Unit::TestCase
  # Our test_helper.rb sets allow_net_connect = false in an inherited #setup
  # method. Disable that here to test the default setting.
  def setup; end
  def teardown; end

  def test_allow_net_connect_is_true_by_default
    assert FakeWeb.allow_net_connect?
  end
end
