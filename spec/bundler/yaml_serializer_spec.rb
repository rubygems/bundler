# frozen_string_literal: true
require "spec_helper"
require "bundler/yaml_serializer"

describe Bundler::YAMLSerializer do
  subject(:serializer) { Bundler::YAMLSerializer }

  describe "#dump" do
    it "works for simple hash" do
      hash = { "Q" => "Where does Thursday come before Wednesday?",
               "Ans" => "In the dictionary. :P" }

      expected = strip_whitespace <<-YAML
          ---
          Q: "Where does Thursday come before Wednesday?"
          Ans: "In the dictionary. :P"
      YAML

      expect(serializer.dump(hash)).to eq(expected)
    end

    it "handles nested hash" do
      hash = {
        "a_joke" => {
          "my-stand" => "I can totally keep secrets",
          "my-explanation" => "It's the people I tell them to that can't",
        },
        "read_ahead" => "All generalizations are false, including this one",
      }

      expected = strip_whitespace <<-YAML
          ---
          a_joke:
            my-stand: "I can totally keep secrets"
            my-explanation: "It's the people I tell them to that can't"
          read_ahead: "All generalizations are false, including this one"
      YAML

      expect(serializer.dump(hash)).to eq(expected)
    end
  end

  describe "#load" do
    it "works for simple hash" do
      yaml = strip_whitespace <<-YAML
        ---
        Jon: "Air is free dude!"
        Jack: "Yes.. until you buy a bag of chips!"
      YAML

      hash = {
        "Jon" => "Air is free dude!",
        "Jack" => "Yes.. until you buy a bag of chips!",
      }

      expect(serializer.load(yaml)).to eq(hash)
    end

    it "works for nested hash" do
      yaml = strip_whitespace <<-YAML
        baa:
          baa: "black sheep"
          have: "you any wool?"
          yes: "merry have I"
        three: "bags full"
      YAML

      hash = {
        "baa" => {
          "baa" => "black sheep",
          "have" => "you any wool?",
          "yes" => "merry have I",
        },
        "three" => "bags full",
      }

      expect(serializer.load(yaml)).to eq(hash)
    end

    it "handles colon in key/value" do
      yaml = strip_whitespace <<-YAML
        BUNDLE_MIRROR__HTTPS://RUBYGEMS__ORG/: http://rubygems-mirror.org
      YAML

      expect(serializer.load(yaml)).to eq("BUNDLE_MIRROR__HTTPS://RUBYGEMS__ORG/" => "http://rubygems-mirror.org")
    end
  end
end
