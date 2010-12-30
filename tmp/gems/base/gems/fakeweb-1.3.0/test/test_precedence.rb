require 'test_helper'

class TestPrecedence < Test::Unit::TestCase

  def test_matching_get_strings_have_precedence_over_matching_get_regexes
    FakeWeb.register_uri(:get, "http://example.com/test", :body => "string")
    FakeWeb.register_uri(:get, %r|http://example\.com/test|, :body => "regex")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "string", response.body
  end

  def test_matching_any_strings_have_precedence_over_matching_any_regexes
    FakeWeb.register_uri(:any, "http://example.com/test", :body => "string")
    FakeWeb.register_uri(:any, %r|http://example\.com/test|, :body => "regex")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "string", response.body
  end

  def test_matching_get_strings_have_precedence_over_matching_any_strings
    FakeWeb.register_uri(:get, "http://example.com/test", :body => "get method")
    FakeWeb.register_uri(:any, "http://example.com/test", :body => "any method")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "get method", response.body

    # registration order should not matter
    FakeWeb.register_uri(:any, "http://example.com/test2", :body => "any method")
    FakeWeb.register_uri(:get, "http://example.com/test2", :body => "get method")
    response = Net::HTTP.start("example.com") { |query| query.get('/test2') }
    assert_equal "get method", response.body
  end

  def test_matching_any_strings_have_precedence_over_matching_get_regexes
    FakeWeb.register_uri(:any, "http://example.com/test", :body => "any string")
    FakeWeb.register_uri(:get, %r|http://example\.com/test|, :body => "get regex")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "any string", response.body
  end

  def test_registered_strings_and_uris_are_equivalent_so_second_takes_precedence
    FakeWeb.register_uri(:get, "http://example.com/test", :body => "string")
    FakeWeb.register_uri(:get, URI.parse("http://example.com/test"), :body => "uri")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "uri", response.body

    FakeWeb.register_uri(:get, URI.parse("http://example.com/test2"), :body => "uri")
    FakeWeb.register_uri(:get, "http://example.com/test2", :body => "string")
    response = Net::HTTP.start("example.com") { |query| query.get('/test2') }
    assert_equal "string", response.body
  end

  def test_identical_registration_replaces_previous_registration
    FakeWeb.register_uri(:get, "http://example.com/test", :body => "first")
    FakeWeb.register_uri(:get, "http://example.com/test", :body => "second")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "second", response.body
  end

  def test_identical_registration_replaces_previous_registration_accounting_for_normalization
    FakeWeb.register_uri(:get, "http://example.com/test?", :body => "first")
    FakeWeb.register_uri(:get, "http://example.com:80/test", :body => "second")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "second", response.body
  end

  def test_identical_registration_replaces_previous_registration_accounting_for_query_params
    FakeWeb.register_uri(:get, "http://example.com/test?a=1&b=2", :body => "first")
    FakeWeb.register_uri(:get, "http://example.com/test?b=2&a=1", :body => "second")
    response = Net::HTTP.start("example.com") { |query| query.get('/test?a=1&b=2') }
    assert_equal "second", response.body
  end

  def test_identical_registration_replaces_previous_registration_with_regexes
    FakeWeb.register_uri(:get, /test/, :body => "first")
    FakeWeb.register_uri(:get, /test/, :body => "second")
    response = Net::HTTP.start("example.com") { |query| query.get('/test') }
    assert_equal "second", response.body
  end

end
