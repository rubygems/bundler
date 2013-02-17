begin
  require 'openssl'
  OpenSSL # ensure OpenSSL is loaded

  vendor = File.expand_path('../vendor', __FILE__)
  $:.unshift(vendor) unless $:.include?(vendor)
  require 'net/http/persistent'

  USE_PERSISTENT = true

rescue LoadError, NameError => e
  require 'net/http'
  USE_PERSISTENT = false

end
