module Bundler
  def self.with_friendly_errors
    begin
      yield
    rescue Bundler::BundlerError => e
      Bundler.ui.error e.message, :wrap => true
      Bundler.ui.trace e
      exit e.status_code
    rescue Interrupt => e
      Bundler.ui.error "\nQuitting..."
      Bundler.ui.trace e
      exit 1
    rescue SystemExit => e
      exit e.status
    rescue Exception => e
      Bundler.ui.error <<-ERR, :wrap => true
        Unfortunately, a fatal error has occurred. Please see the Bundler
        troubleshooting documentation at http://bit.ly/bundler-issues. Thanks!

      ERR
      raise e
    end
  end
end
