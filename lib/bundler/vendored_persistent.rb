begin
  require 'openssl'
  # ensure OpenSSL is loaded
  OpenSSL
rescue LoadError, NameError => e
  raise Bundler::HTTPError, "\nCould not load OpenSSL." \
    "\nYou must recompile Ruby with OpenSSL support or change the sources in your" \
    "\nGemfile from 'https' to 'http'. Instructions for compiling with OpenSSL" \
    "\nusing RVM are available at rvm.io/packages/openssl."
end

vendor = File.expand_path('../vendor', __FILE__)
$:.unshift(vendor) unless $:.include?(vendor)
require 'net/http/persistent'
