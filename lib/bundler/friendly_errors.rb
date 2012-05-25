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
    rescue Exception => e
      Bundler.ui.error "Unfortunately, a fatal error has occurred. " +
        "Please report this error to the Bundler issue tracker at " +
        "https://github.com/carlhuda/bundler/issues so that we can fix it. " +
        "Please include the full output of the command, your Gemfile and Gemfile.lock. " +
        "Thanks!"
      raise e
    end
  end
end
