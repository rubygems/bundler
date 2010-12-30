require 'test_helper'

class TestFakeWebTrailingSlashes < Test::Unit::TestCase

  def test_registering_root_without_slash_and_ask_predicate_method_with_slash
    FakeWeb.register_uri(:get, "http://www.example.com", :body => "root")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com/")
  end

  def test_registering_root_without_slash_and_request
    FakeWeb.register_uri(:get, "http://www.example.com", :body => "root")
    response = Net::HTTP.start("www.example.com") { |query| query.get('/') }
    assert_equal "root", response.body
  end

  def test_registering_root_with_slash_and_ask_predicate_method_without_slash
    FakeWeb.register_uri(:get, "http://www.example.com/", :body => "root")
    assert FakeWeb.registered_uri?(:get, "http://www.example.com")
  end

  def test_registering_root_with_slash_and_request
    FakeWeb.register_uri(:get, "http://www.example.com/", :body => "root")
    response = Net::HTTP.start("www.example.com") { |query| query.get('/') }
    assert_equal "root", response.body
  end

  def test_registering_path_without_slash_and_ask_predicate_method_with_slash
    FakeWeb.register_uri(:get, "http://www.example.com/users", :body => "User list")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com/users/")
  end

  def test_registering_path_without_slash_and_request_with_slash
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:get, "http://www.example.com/users", :body => "User list")
    assert_raise FakeWeb::NetConnectNotAllowedError do
      response = Net::HTTP.start("www.example.com") { |query| query.get('/users/') }
    end
  end

  def test_registering_path_with_slash_and_ask_predicate_method_without_slash
    FakeWeb.register_uri(:get, "http://www.example.com/users/", :body => "User list")
    assert !FakeWeb.registered_uri?(:get, "http://www.example.com/users")
  end

  def test_registering_path_with_slash_and_request_without_slash
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:get, "http://www.example.com/users/", :body => "User list")
    assert_raise FakeWeb::NetConnectNotAllowedError do
      response = Net::HTTP.start("www.example.com") { |query| query.get('/users') }
    end
  end

end
