require 'test_helper'

class TestOtherNetHttpLibraries < Test::Unit::TestCase

  def capture_output_from_requiring(libs, additional_code = "")
    requires = libs.map { |lib| "require '#{lib}'" }.join("; ")
    fakeweb_dir = "#{File.dirname(__FILE__)}/../lib"
    vendor_dirs = Dir["#{File.dirname(__FILE__)}/vendor/*/lib"]
    load_path_opts = vendor_dirs.unshift(fakeweb_dir).map { |dir| "-I#{dir}" }.join(" ")

    `#{ruby_path} #{load_path_opts} -e "#{requires}; #{additional_code}" 2>&1`
  end

  def test_requiring_samuel_before_fakeweb_prints_warning
    output = capture_output_from_requiring %w(samuel fakeweb)
    assert_match %r(Warning: FakeWeb was loaded after Samuel), output
  end

  def test_requiring_samuel_after_fakeweb_does_not_print_warning
    output = capture_output_from_requiring %w(fakeweb samuel)
    assert output.empty?
  end

  def test_requiring_right_http_connection_before_fakeweb_and_then_connecting_does_not_print_warning
    additional_code = "Net::HTTP.start('example.com')"
    output = capture_output_from_requiring %w(right_http_connection fakeweb), additional_code
    assert output.empty?
  end

  def test_requiring_right_http_connection_after_fakeweb_and_then_connecting_prints_warning
    additional_code = "Net::HTTP.start('example.com')"
    output = capture_output_from_requiring %w(fakeweb right_http_connection), additional_code
    assert_match %r(Warning: RightHttpConnection was loaded after FakeWeb), output
  end

end
