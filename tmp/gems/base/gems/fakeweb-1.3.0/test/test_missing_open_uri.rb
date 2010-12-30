require 'test_helper'

class TestMissingOpenURI < Test::Unit::TestCase

  def setup
    super
    @saved_open_uri = OpenURI
    Object.send(:remove_const, :OpenURI)
  end

  def teardown
    super
    Object.const_set(:OpenURI, @saved_open_uri)
  end


  def test_register_using_exception_without_open_uri
    # regression test for Responder needing OpenURI::HTTPError to be defined
    FakeWeb.register_uri(:get, "http://example.com/", :exception => StandardError)
    assert_raises(StandardError) do
      Net::HTTP.start("example.com") { |http| http.get("/") }
    end
  end

end
