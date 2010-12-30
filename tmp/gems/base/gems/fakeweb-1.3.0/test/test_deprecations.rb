require 'test_helper'

class TestDeprecations < Test::Unit::TestCase

  def test_register_uri_without_method_argument_prints_deprecation_warning
    warning = capture_stderr do
      FakeWeb.register_uri("http://example.com", :body => "test")
    end
    assert_match %r(deprecation warning: fakeweb)i, warning
  end

  def test_registered_uri_without_method_argument_prints_deprecation_warning
    warning = capture_stderr do
      FakeWeb.registered_uri?("http://example.com")
    end
    assert_match %r(deprecation warning: fakeweb)i, warning
  end

  def test_response_for_without_method_argument_prints_deprecation_warning
    warning = capture_stderr do
      FakeWeb.response_for("http://example.com")
    end
    assert_match %r(deprecation warning: fakeweb)i, warning
  end

  def test_register_uri_without_method_argument_prints_deprecation_warning_with_correct_caller
    warning = capture_stderr do
      FakeWeb.register_uri("http://example.com", :body => "test")
    end
    assert_match %r(Called at.*?test_deprecations\.rb)i, warning
  end

  def test_register_uri_with_string_option_prints_deprecation_warning
    warning = capture_stderr do
      FakeWeb.register_uri(:get, "http://example.com", :string => "test")
    end
    assert_match %r(deprecation warning: fakeweb's :string option)i, warning
  end

  def test_register_uri_with_file_option_prints_deprecation_warning
    warning = capture_stderr do
      FakeWeb.register_uri(:get, "http://example.com", :file => fixture_path("test_example.txt"))
    end
    assert_match %r(deprecation warning: fakeweb's :file option)i, warning
  end

  def test_register_uri_with_string_option_prints_deprecation_warning_with_correct_caller
    warning = capture_stderr do
      FakeWeb.register_uri(:get, "http://example.com", :string => "test")
    end
    assert_match %r(Called at.*?test_deprecations\.rb)i, warning
  end

end
