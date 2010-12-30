require 'test_helper'

class TestUtility < Test::Unit::TestCase

  def test_decode_userinfo_from_header_handles_basic_auth
    authorization_header = "Basic dXNlcm5hbWU6c2VjcmV0"
    userinfo = FakeWeb::Utility.decode_userinfo_from_header(authorization_header)
    assert_equal "username:secret", userinfo
  end

  def test_encode_unsafe_chars_in_userinfo_does_not_encode_userinfo_safe_punctuation
    userinfo = "user;&=+$,:secret"
    assert_equal userinfo, FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo)
  end

  def test_encode_unsafe_chars_in_userinfo_does_not_encode_rfc_3986_unreserved_characters
    userinfo = "-_.!~*'()abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:secret"
    assert_equal userinfo, FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo)
  end

  def test_encode_unsafe_chars_in_userinfo_does_encode_other_characters
    userinfo, safe_userinfo = 'us#rn@me:sec//ret?"', 'us%23rn%40me:sec%2F%2Fret%3F%22'
    assert_equal safe_userinfo, FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo)
  end

  def test_strip_default_port_from_uri_strips_80_from_http_with_path
    uri = "http://example.com:80/foo/bar"
    stripped_uri = FakeWeb::Utility.strip_default_port_from_uri(uri)
    assert_equal "http://example.com/foo/bar", stripped_uri
  end

  def test_strip_default_port_from_uri_strips_80_from_http_without_path
    uri = "http://example.com:80"
    stripped_uri = FakeWeb::Utility.strip_default_port_from_uri(uri)
    assert_equal "http://example.com", stripped_uri
  end

  def test_strip_default_port_from_uri_strips_443_from_https_without_path
    uri = "https://example.com:443"
    stripped_uri = FakeWeb::Utility.strip_default_port_from_uri(uri)
    assert_equal "https://example.com", stripped_uri
  end

  def test_strip_default_port_from_uri_strips_443_from_https
    uri = "https://example.com:443/foo/bar"
    stripped_uri = FakeWeb::Utility.strip_default_port_from_uri(uri)
    assert_equal "https://example.com/foo/bar", stripped_uri
  end

  def test_strip_default_port_from_uri_does_not_strip_8080_from_http
    uri = "http://example.com:8080/foo/bar"
    assert_equal uri, FakeWeb::Utility.strip_default_port_from_uri(uri)
  end

  def test_strip_default_port_from_uri_does_not_strip_443_from_http
    uri = "http://example.com:443/foo/bar"
    assert_equal uri, FakeWeb::Utility.strip_default_port_from_uri(uri)
  end

  def test_strip_default_port_from_uri_does_not_strip_80_from_query_string
    uri = "http://example.com/?a=:80&b=c"
    assert_equal uri, FakeWeb::Utility.strip_default_port_from_uri(uri)
  end

  def test_strip_default_port_from_uri_does_not_modify_strings_that_do_not_start_with_http_or_https
    uri = "httpz://example.com:80/"
    assert_equal uri, FakeWeb::Utility.strip_default_port_from_uri(uri)
  end

  def test_request_uri_as_string
    http = Net::HTTP.new("www.example.com", 80)
    request = Net::HTTP::Get.new("/index.html")
    expected = "http://www.example.com:80/index.html"
    assert_equal expected, FakeWeb::Utility.request_uri_as_string(http, request)
  end

  def test_uri_escape_delegates_to_uri_parser_when_available
    parsing_object = URI.const_defined?(:Parser) ? URI::Parser.any_instance : URI
    parsing_object.expects(:escape).with("string", /unsafe/).returns("escaped")
    assert_equal "escaped", FakeWeb::Utility.uri_escape("string", /unsafe/)
  end

end
