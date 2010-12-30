require 'test_helper'

class SamuelTest < Test::Unit::TestCase

  context "logger configuration" do
    setup do
      Samuel.logger = nil
      if Object.const_defined?(:RAILS_DEFAULT_LOGGER)
        Object.send(:remove_const, :RAILS_DEFAULT_LOGGER)
      end
    end

    teardown do
      Samuel.logger = nil
    end

    context "when Rails's logger is available" do
      setup { Object.const_set(:RAILS_DEFAULT_LOGGER, :mock_logger) }

      should "use the same logger" do
        assert_equal :mock_logger, Samuel.logger
      end
    end

    context "when Rails's logger is not available" do
      should "use a new Logger instance pointed to STDOUT" do
        assert_instance_of Logger, Samuel.logger
        assert_equal STDOUT, Samuel.logger.instance_variable_get(:"@logdev").dev
      end
    end
  end


  context ".reset_config" do
    should "reset the config to default vaules" do
      Samuel.config = {:foo => "bar"}
      Samuel.reset_config
      assert_equal({:label => nil, :labels => {"" => "HTTP"}, :filtered_params => []}, Samuel.config)
    end
  end

end
