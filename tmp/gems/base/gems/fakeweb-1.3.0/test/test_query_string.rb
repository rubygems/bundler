require 'test_helper'

class TestFakeWebQueryString < Test::Unit::TestCase

  def test_register_uri_string_with_query_params
    FakeWeb.register_uri(:get, 'http://example.com/?a=1&b=1', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com/?a=1&b=1')

    FakeWeb.register_uri(:post, URI.parse("http://example.org/?a=1&b=1"), :body => "foo")
    assert FakeWeb.registered_uri?(:post, "http://example.org/?a=1&b=1")
  end

  def test_register_uri_with_query_params_and_check_in_different_order
    FakeWeb.register_uri(:get, 'http://example.com/?a=1&b=1', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com/?b=1&a=1')

    FakeWeb.register_uri(:post, URI.parse('http://example.org/?a=1&b=1'), :body => 'foo')
    assert FakeWeb.registered_uri?(:post, 'http://example.org/?b=1&a=1')
  end

  def test_registered_uri_gets_recognized_with_empty_query_params
    FakeWeb.register_uri(:get, 'http://example.com/', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com/?')

    FakeWeb.register_uri(:post, URI.parse('http://example.org/'), :body => 'foo')
    assert FakeWeb.registered_uri?(:post, 'http://example.org/?')
  end

  def test_register_uri_with_empty_query_params_and_check_with_none
    FakeWeb.register_uri(:get, 'http://example.com/?', :body => 'foo')
    assert FakeWeb.registered_uri?(:get, 'http://example.com/')

    FakeWeb.register_uri(:post, URI.parse('http://example.org/?'), :body => 'foo')
    assert FakeWeb.registered_uri?(:post, 'http://example.org/')
  end

  def test_registry_sort_query_params
    assert_equal "a=1&b=2", FakeWeb::Registry.instance.send(:sort_query_params, "b=2&a=1")
  end

  def test_registry_sort_query_params_sorts_by_value_if_keys_collide
    assert_equal "a=1&a=2&b=2", FakeWeb::Registry.instance.send(:sort_query_params, "a=2&b=2&a=1")
  end

end
