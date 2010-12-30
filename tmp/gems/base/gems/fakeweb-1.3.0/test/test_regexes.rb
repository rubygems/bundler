require 'test_helper'

class TestRegexes < Test::Unit::TestCase

  def test_registered_uri_with_pattern
    FakeWeb.register_uri(:get, %r|http://example.com/test_example/\d+|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://example.com/test_example/25")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/test_example/abc")
  end

  def test_response_for_with_matching_registered_uri
    FakeWeb.register_uri(:get, %r|http://www.google.com|, :body => "Welcome to Google!")
    assert_equal "Welcome to Google!", FakeWeb.response_for(:get, "http://www.google.com").body
  end

  def test_response_for_with_matching_registered_uri_and_get_method_matching_to_any_method
    FakeWeb.register_uri(:any, %r|http://www.example.com|, :body => "example")
    assert_equal "example", FakeWeb.response_for(:get, "http://www.example.com").body
  end

  def test_registered_uri_with_authentication_and_pattern
    FakeWeb.register_uri(:get, %r|http://user:pass@mock/example\.\w+|i, :body => "example")
    assert FakeWeb.registered_uri?(:get, 'http://user:pass@mock/example.txt')
  end

  def test_registered_uri_with_authentication_and_pattern_handles_case_insensitivity
    FakeWeb.register_uri(:get, %r|http://user:pass@mock/example\.\w+|i, :body => "example")
    assert FakeWeb.registered_uri?(:get, 'http://uSeR:PAss@mock/example.txt')
  end

  def test_request_with_authentication_and_pattern_handles_case_insensitivity
    FakeWeb.register_uri(:get, %r|http://user:pass@mock/example\.\w+|i, :body => "example")
    http = Net::HTTP.new('mock', 80)
    req = Net::HTTP::Get.new('/example.txt')
    req.basic_auth 'uSeR', 'PAss'
    assert_equal "example", http.request(req).body
  end

  def test_requesting_a_uri_that_matches_two_registered_regexes_raises_an_error
    FakeWeb.register_uri(:get, %r|http://example\.com/|, :body => "first")
    FakeWeb.register_uri(:get, %r|http://example\.com/a|, :body => "second")
    assert_raise FakeWeb::MultipleMatchingURIsError do
      Net::HTTP.start("example.com") { |query| query.get('/a') }
    end
  end

  def test_requesting_a_uri_that_matches_two_registered_regexes_raises_an_error_including_request_info
    FakeWeb.register_uri(:get, %r|http://example\.com/|, :body => "first")
    FakeWeb.register_uri(:get, %r|http://example\.com/a|, :body => "second")
    begin
      Net::HTTP.start("example.com") { |query| query.get('/a') }
    rescue FakeWeb::MultipleMatchingURIsError => exception
    end
    assert exception.message.include?("GET http://example.com/a")
  end

  def test_registry_does_not_find_using_mismatched_protocols_or_ports_when_registered_with_both
    FakeWeb.register_uri(:get, %r|http://www.example.com:80|, :body => "example")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com:80")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com:443")
  end

  def test_registry_finds_using_non_default_port
    FakeWeb.register_uri(:get, %r|example\.com:8080|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:8080/path")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:8080/path")
  end

  def test_registry_finds_using_default_port_and_http_when_registered_with_explicit_port_80
    FakeWeb.register_uri(:get, %r|example\.com:80|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com/path")

    # check other permutations, too
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:80/path")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:8080/path")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:80/path")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:8080/path")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com/path")
  end

  def test_registry_finds_using_default_port_and_https_when_registered_with_explicit_port_443
    FakeWeb.register_uri(:get, %r|example\.com:443|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com/path")

    # check other permutations, too
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:443/path")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:44321/path")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:443/path")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:44321/path")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com/path")
  end

  def test_registry_only_finds_using_default_port_when_registered_without_if_protocol_matches
    FakeWeb.register_uri(:get, %r|http://www.example.com/test|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:80/test")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com:443/test")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com:443/test")
    FakeWeb.register_uri(:get, %r|https://www.example.org/test|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "https://www.example.org:443/test")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.org:80/test")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.org:80/test")
  end

  def test_registry_matches_using_mismatched_port_when_registered_without
    FakeWeb.register_uri(:get, %r|http://www.example.com|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:80")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:443")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:12345")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com:443")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com")
  end

  def test_registry_matches_using_default_port_for_protocol_when_registered_without_protocol_or_port
    FakeWeb.register_uri(:get, %r|www.example.com/home|, :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com/home")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com/home")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com:80/home")
    assert FakeWeb.registered_uri?(:get, "https://www.example.com:443/home")
    assert !FakeWeb.registered_uri?(:get, "https://www.example.com:80/home")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com:443/home")
  end

  def test_registry_matches_with_query_params
    FakeWeb.register_uri(:get, %r[example.com/list\?(.*&|)important=1], :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://example.com/list?hash=123&important=1&unimportant=2")
    assert FakeWeb.registered_uri?(:get, "http://example.com/list?hash=123&important=12&unimportant=2")
    assert FakeWeb.registered_uri?(:get, "http://example.com/list?important=1&unimportant=2")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?important=2")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?important=2&unimportant=1")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?hash=123&important=2&unimportant=1")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?notimportant=1&unimportant=1")
  end

  def test_registry_does_not_match_when_regex_has_unsorted_query_params
    FakeWeb.register_uri(:get, %r[example\.com/list\?b=2&a=1], :body => "example")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?b=2&a=1")
    assert !FakeWeb.registered_uri?(:get, "http://example.com/list?a=1&b=2")
    assert !FakeWeb.registered_uri?(:get, "https://example.com:443/list?b=2&a=1")
  end

  def test_registry_matches_when_regex_has_sorted_query_params
    FakeWeb.register_uri(:get, %r[example\.com/list\?a=1&b=2], :body => "example")
    assert FakeWeb.registered_uri?(:get, "http://example.com/list?b=2&a=1")
    assert FakeWeb.registered_uri?(:get, "http://example.com/list?a=1&b=2")
    assert FakeWeb.registered_uri?(:get, "https://example.com:443/list?b=2&a=1")
  end

  def test_registry_matches_quickly_with_lots_of_query_params
    # regression test for code that tried to calculate the permutations of the
    # query params, which hangs with a large number of params
    FakeWeb.register_uri(:get, %r[example.com], :body => "example")
    Timeout::timeout(1) do
      FakeWeb.registered_uri?(:get, "http://example.com/?a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8")
    end
  end

end
