# frozen_string_literal: true
require "spec_helper"

describe Bundler::URICredentialsFilter do
  subject { described_class }

  describe "#anonymized_uri" do
    context "uri is a uri object" do
      let(:uri) { URI("https://#{credentials}github.com/company/private-repo") }

      context "that contains credentials" do
        let(:credentials) { "oauth_token:x-oauth-basic@" }

        it "returns the uri without the credentials" do
          expect(subject.anonymized_uri(uri)).to eq(URI("https://github.com/company/private-repo"))
        end
      end

      context "that does not contains credentials" do
        let(:credentials) { "" }

        it "returns the same uri" do
          # https://github.com/company/private-repo is not a valid URI in ruby 1.8.7
          if RUBY_VERSION > "1.8.7"
            expect(subject.anonymized_uri(uri)).to eq(URI(uri))
          else
            expect(subject.anonymized_uri(uri)).to eq(uri)
          end
        end
      end
    end

    context "uri is a uri string" do
      let(:uri) { "https://#{credentials}github.com/company/private-repo" }

      context "that contains credentials" do
        let(:credentials) { "oauth_token:x-oauth-basic@" }

        it "returns the uri without the credentials" do
          expect(subject.anonymized_uri(uri)).to eq(URI("https://github.com/company/private-repo"))
        end
      end

      context "that does not contains credentials" do
        let(:credentials) { "" }

        it "returns the same uri" do
          expect(subject.anonymized_uri(uri)).to eq(URI(uri))
        end
      end
    end

    context "uri is a non-uri format string (ex. path)" do
      let(:uri) { "/path/to/repo" }

      it "returns the same uri" do
        expect(subject.anonymized_uri(uri)).to eq(URI(uri))
      end
    end

    context "uri is nil" do
      let(:uri) { nil }

      it "returns nil" do
        expect(subject.anonymized_uri(uri)).to be_nil
      end
    end
  end

  describe "#credentials_filtered_string" do
    let(:str_to_filter) { "This is a git message containing a uri #{uri}!" }
    let(:credentials)   { "" }
    let(:uri)           { URI("https://#{credentials}github.com/company/private-repo") }

    context "with a uri that contains credentials" do
      let(:credentials) { "oauth_token:x-oauth-basic@" }

      it "returns the string without the credentials" do
        expect(subject.credentials_filtered_string(str_to_filter, uri)).to eq(
          "This is a git message containing a uri https://github.com/company/private-repo!")
      end
    end

    context "that does not contains credentials" do
      it "returns the same string" do
        expect(subject.credentials_filtered_string(str_to_filter, uri)).to eq(str_to_filter)
      end
    end

    context "string to filter is nil" do
      let(:str_to_filter) { nil }

      it "returns nil" do
        expect(subject.credentials_filtered_string(str_to_filter, uri)).to be_nil
      end
    end

    context "uri to filter out is nil" do
      let(:uri) { nil }

      it "returns the same string" do
        expect(subject.credentials_filtered_string(str_to_filter, uri)).to eq(str_to_filter)
      end
    end
  end
end
