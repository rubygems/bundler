require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Resolver" do
  describe "with a single gem" do
    before(:each) do
      @index = build_index do
        add_spec "foo", "0.2.2"
      end
    end

    it "can search for that gem" do
      specs = @index.find_name("foo", "=0.2.2")
      specs.should match_gems(
        "foo" => ["0.2.2"]
      )
    end
  end

  describe "with a lots of gems" do
    before(:each) do
      @index = build_index do
        add_spec "foo", "0.2.1"
        add_spec "foo", "0.2.2"
        add_spec "foo", "0.3.0"
        add_spec "foo", "1.1.0"

        add_spec "bar", "0.2.2"
        add_spec "bar", "0.2.3"
        add_spec "bar", "0.2.4"
        add_spec "bar", "0.2.5"
        add_spec "bar", "0.3.5"
        add_spec "bar", "0.4.5"
      end
    end

    it "can search for 'foo', '>= 0.2.2'" do
      specs = @index.find_name("foo", ">= 0.2.2")
      specs.should match_gems(
        "foo" => ["0.2.2", "0.3.0", "1.1.0"]
      )
    end
  end
end
