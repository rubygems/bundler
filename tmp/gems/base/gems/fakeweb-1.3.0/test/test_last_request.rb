require 'test_helper'

class TestLastRequest < Test::Unit::TestCase

  def test_last_request_returns_correct_net_http_request_class
    FakeWeb.register_uri(:get, "http://example.com", :status => [200, "OK"])
    Net::HTTP.start("example.com") { |http| http.get("/") }
    assert_instance_of Net::HTTP::Get, FakeWeb.last_request
  end

  def test_last_request_has_correct_method_path_and_body_for_get
    FakeWeb.register_uri(:get, "http://example.com", :status => [200, "OK"])
    Net::HTTP.start("example.com") { |http| http.get("/") }
    assert_equal "GET", FakeWeb.last_request.method
    assert_equal "/", FakeWeb.last_request.path
    assert_nil FakeWeb.last_request.body
    assert_nil FakeWeb.last_request.content_length
  end

  def test_last_request_has_correct_method_path_and_body_for_post
    FakeWeb.register_uri(:post, "http://example.com/posts", :status => [201, "Created"])
    Net::HTTP.start("example.com") { |http| http.post("/posts", "title=Test") }
    assert_equal "POST", FakeWeb.last_request.method
    assert_equal "/posts", FakeWeb.last_request.path
    assert_equal "title=Test", FakeWeb.last_request.body
    assert_equal 10, FakeWeb.last_request.content_length
  end

end
