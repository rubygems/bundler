require 'spec_helper'

describe Bundler::S3Fetcher do
  before do
    allow(Bundler).to receive(:root){ Pathname.new("root") }
  end

  describe "sign" do
    it "requires authentication" do
      url = "s3://foo"
      expect { Bundler::S3Fetcher.new(url).sign(URI(url))}.to raise_error(Bundler::GemspecError)
    end

    it "signs S3 requests" do
      accessId = "AKHAJIHAFOW6WWJUV5RA"
      Gem.configuration[:s3_source] = {"foo" => {
        :id => accessId,
        :secret => "7UVCy7cYjEzwfwLwwQR/DlOdJ7V+c7GFWKZDn8yx9"
      } }
      url = "s3://foo/"
      time = Time.utc(2014, 6, 1).to_i

      actual = Bundler::S3Fetcher.new(url).sign(URI(url), time)
      expect(actual.host).to eq "foo.s3.amazonaws.com"
      expect(actual.scheme).to eq "https"
      query = CGI.parse(actual.query)
      expect(query['AWSAccessKeyId']).to eq [accessId]
      expect(query['Expires']).to eq [time.to_s]
      expect(query['Signature']).to eq ["9IrED0v8ae/VwAr0E9eoy9mcE4Y="]
    end
  end
end
