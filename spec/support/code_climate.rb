module Spec
  module CodeClimate
    def self.setup
      require "codeclimate-test-reporter"
      ::CodeClimate::TestReporter.start
    rescue LoadError
      # it's fine if CodeClimate isn't set up
      nil
    end
  end
end
