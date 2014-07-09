require 'base64'
require 'openssl'

module Bundler
  class S3Fetcher < Fetcher

    def fetch(uri, counter = 0)
      super(sign(uri), counter)
    end

    # Instead of taking a dependency on aws-sdk, use a method modeled on
    # the signing method in https://github.com/rubygems/rubygems/pull/856
    def sign(uri, expiration = default_expiration)
      uri = uri.dup
      unless uri.user && uri.password
        raise AuthenticationRequiredError.new("credentials needed in s3 source, like s3://key:secret@bucket-name/")
      end

      payload = "GET\n\n\n#{expiration}\n/#{uri.host}#{uri.path}"
      digest = OpenSSL::HMAC.digest('sha1', uri.password, payload)
      # URI.escape is deprecated, and there isn't yet a replacement that does quite what we want
      signature = Base64.encode64(digest).gsub("\n", '').gsub(/[\+\/=]/) { |c| BASE64_URI_TRANSLATE[c] }
      uri.query = [uri.query, "AWSAccessKeyId=#{uri.user}&Expires=#{expiration}&Signature=#{signature}"].compact.join('&')
      uri.user = nil
      uri.password = nil
      uri.scheme = "https"
      uri.host = [uri.host, "s3.amazonaws.com"].join('.')

      URI.parse(uri.to_s)
    end

    def default_expiration
      (Time.now + 3600).to_i # one hour from now
    end

    BASE64_URI_TRANSLATE = { '+' => '%2B', '/' => '%2F', '=' => '%3D' }.freeze
    protected
      # The s3 fetcher does not use the username and password for basic auth,
      # so this is a no-op
      def add_basic_auth(req)
      end
  end
end