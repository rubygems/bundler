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
      id, secret = s3_source_auth uri.host
      expiration ||= default_expiration
      canonical_path = "/#{uri.host}#{uri.path}"
      payload = "GET\n\n\n#{expiration}\n#{canonical_path}"
      digest = OpenSSL::HMAC.digest('sha1', secret, payload)
      # URI.escape is deprecated, and there isn't yet a replacement that does quite what we want
      signature = Base64.encode64(digest).gsub("\n", '').gsub(/[\+\/=]/) { |c| BASE64_URI_TRANSLATE[c] }
      URI.parse("https://#{uri.host}.s3.amazonaws.com#{uri.path}?AWSAccessKeyId=#{id}&Expires=#{expiration}&Signature=#{signature}")
    end

    def default_expiration
      (Time.now + 3600).to_i # one hour from now
    end

    # Gem configuration appears to be mutable within the Gemfile in case of project-specific AWS keys not present in the .gemrc:
    #
    # Gem.configuration[:s3_source] = {'bucketname' => {id: 'aws id', secret: 'aws secret'}}
    def s3_source_auth(host)
      s3_source = Gem.configuration[:s3_source] || Gem.configuration['s3_source']
      raise GemspecError.new('no s3_source key exists in .gemrc') unless s3_source
      auth = s3_source[host] || s3_source[host.to_sym]
      raise GemspecError.new("no key for host #{host} in s3_source in .gemrc") unless auth
      id = auth[:id] || auth['id']
      secret = auth[:secret] || auth['secret']
      raise  GemspecError.new("s3_source for #{host} missing id or secret") unless id and secret
      [id, secret]
    end

    BASE64_URI_TRANSLATE = { '+' => '%2B', '/' => '%2F', '=' => '%3D' }.freeze
    protected
      # The s3 fetcher does not use the username and password for basic auth,
      # so this is a no-op
      def add_basic_auth(req)
      end
  end
end
