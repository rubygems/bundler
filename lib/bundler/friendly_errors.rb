module Bundler
  def self.with_friendly_errors
    begin
      yield
    rescue Bundler::BundlerError => e
      Bundler.ui.error e.message
      Bundler.ui.debug e.backtrace.join("\n")
      exit e.status_code
    rescue Interrupt => e
      Bundler.ui.error "\nQuitting..."
      Bundler.ui.debug e.backtrace.join("\n")
      exit 1
    rescue SystemExit => e
      exit e.status
    rescue LoadError => e
      case e.message
      when /cannot load such file -- openssl/, /openssl.so/, /libcrypto.so/
        Bundler.ui.error "\nCould not load OpenSSL."
        Bundler.ui.warn "You must recompile Ruby with OpenSSL support or change the sources in your" \
          "\nGemfile from 'https' to 'http'. Instructions for compiling with OpenSSL" \
          "\nusing RVM are available at rvm.io/packages/openssl."
        Bundler.ui.debug "#{e.class}: #{e.message}"
        Bundler.ui.debug e.backtrace.join("\n")
        exit 1
      else
        raise e
      end
    rescue Exception => e
      Bundler.ui.error(
        "Unfortunately, a fatal error has occurred. Please see the Bundler \n" \
        "troubleshooting documentation at http://bit.ly/bundler-issues. Thanks! \n")
      raise e
    end
  end
end
