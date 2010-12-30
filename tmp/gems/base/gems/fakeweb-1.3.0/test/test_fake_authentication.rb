require 'test_helper'

class TestFakeAuthentication < Test::Unit::TestCase

  def test_register_uri_with_authentication
    FakeWeb.register_uri(:get, 'http://user:pass@mock/test_example.txt', :body => "example")
    assert FakeWeb.registered_uri?(:get, 'http://user:pass@mock/test_example.txt')
  end

  def test_register_uri_with_authentication_doesnt_trigger_without
    FakeWeb.register_uri(:get, 'http://user:pass@mock/test_example.txt', :body => "example")
    assert !FakeWeb.registered_uri?(:get, 'http://mock/test_example.txt')
  end

  def test_register_uri_with_authentication_doesnt_trigger_with_incorrect_credentials
    FakeWeb.register_uri(:get, 'http://user:pass@mock/test_example.txt', :body => "example")
    assert !FakeWeb.registered_uri?(:get, 'http://user:wrong@mock/test_example.txt')
  end

  def test_unauthenticated_request
    FakeWeb.register_uri(:get, 'http://mock/auth.txt', :body => 'unauthorized')
    http = Net::HTTP.new('mock', 80)
    req = Net::HTTP::Get.new('/auth.txt')
    assert_equal 'unauthorized', http.request(req).body
  end

  def test_authenticated_request
    FakeWeb.register_uri(:get, 'http://user:pass@mock/auth.txt', :body => 'authorized')
    http = Net::HTTP.new('mock',80)
    req = Net::HTTP::Get.new('/auth.txt')
    req.basic_auth 'user', 'pass'
    assert_equal 'authorized', http.request(req).body
  end

  def test_authenticated_request_where_only_userinfo_differs
    FakeWeb.register_uri(:get, 'http://user:pass@mock/auth.txt', :body => 'first user')
    FakeWeb.register_uri(:get, 'http://user2:pass@mock/auth.txt', :body => 'second user')
    http = Net::HTTP.new('mock')
    req = Net::HTTP::Get.new('/auth.txt')
    req.basic_auth 'user2', 'pass'
    assert_equal 'second user', http.request(req).body
  end

  def test_basic_auth_support_is_transparent_to_oauth
    FakeWeb.register_uri(:get, "http://sp.example.com/protected", :body => "secret")

    # from http://oauth.net/core/1.0/#auth_header
    auth_header = <<-HEADER
      OAuth realm="http://sp.example.com/",
            oauth_consumer_key="0685bd9184jfhq22",
            oauth_token="ad180jjd733klru7",
            oauth_signature_method="HMAC-SHA1",
            oauth_signature="wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D",
            oauth_timestamp="137131200",
            oauth_nonce="4572616e48616d6d65724c61686176",
            oauth_version="1.0"
    HEADER
    auth_header.gsub!(/\s+/, " ").strip!

    http = Net::HTTP.new("sp.example.com", 80)
    response = nil
    http.start do |request|
      response = request.get("/protected", {"authorization" => auth_header})
    end
    assert_equal "secret", response.body
  end

  def test_basic_auth_when_userinfo_contains_allowed_unencoded_characters
    FakeWeb.register_uri(:get, "http://roses&hel1o,(+$):so;longs=@example.com", :body => "authorized")
    http = Net::HTTP.new("example.com")
    request = Net::HTTP::Get.new("/")
    request.basic_auth("roses&hel1o,(+$)", "so;longs=")
    assert_equal "authorized", http.request(request).body
  end

  def test_basic_auth_when_userinfo_contains_encoded_at_sign
    FakeWeb.register_uri(:get, "http://user%40example.com:secret@example.com", :body => "authorized")
    http = Net::HTTP.new("example.com")
    request = Net::HTTP::Get.new("/")
    request.basic_auth("user@example.com", "secret")
    assert_equal "authorized", http.request(request).body
  end

  def test_basic_auth_when_userinfo_contains_allowed_encoded_characters
    FakeWeb.register_uri(:get, "http://us%20er:sec%20%2F%2Fret%3F@example.com", :body => "authorized")
    http = Net::HTTP.new("example.com")
    request = Net::HTTP::Get.new("/")
    request.basic_auth("us er", "sec //ret?")
    assert_equal "authorized", http.request(request).body
  end

end
