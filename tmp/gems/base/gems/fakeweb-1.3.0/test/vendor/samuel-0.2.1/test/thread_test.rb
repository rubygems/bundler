require 'test_helper'

class ThreadTest < Test::Unit::TestCase

  context "when logging multiple requests at once" do
    setup do
      @log = StringIO.new
      Samuel.logger = Logger.new(@log)
      FakeWeb.register_uri(:get, /example\.com/, :status => [200, "OK"])
      threads = []
      5.times do |i|
        threads << Thread.new(i) do |n|
          Samuel.with_config :label => "Example #{n}" do
            Thread.pass
            open "http://example.com/#{n}"
          end
        end
      end
      threads.each { |t| t.join }
      @log.rewind
    end

    should "not let configuration blocks interfere with eachother" do
      @log.each_line do |line|
        matches = %r|Example (\d+).*example\.com/(\d+)|.match(line)
        assert_not_nil matches
        assert_equal matches[1], matches[2]
      end
    end
  end

end
