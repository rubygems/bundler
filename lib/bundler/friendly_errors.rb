# encoding: utf-8
require "bundler/vendored_thor"

module Bundler
  def self.with_friendly_errors
    yield
  rescue Bundler::BundlerError => e
    Bundler.ui.error e.message, :wrap => true
    Bundler.ui.trace e
    exit e.status_code
  rescue Thor::AmbiguousTaskError => e
    Bundler.ui.error e.message
    exit 15
  rescue Thor::UndefinedTaskError => e
    Bundler.ui.error e.message
    exit 15
  rescue Thor::Error => e
    Bundler.ui.error e.message
    exit 1
  rescue LoadError => e
    raise e unless e.message =~ /cannot load such file -- openssl|openssl.so|libcrypto.so/
    Bundler.ui.error "\nCould not load OpenSSL."
    Bundler.ui.warn <<-WARN, :wrap => true
      You must recompile Ruby with OpenSSL support or change the sources in your \
      Gemfile from 'https' to 'http'. Instructions for compiling with OpenSSL \
      using RVM are available at http://rvm.io/packages/openssl.
    WARN
    Bundler.ui.trace e
    exit 1
  rescue Interrupt => e
    Bundler.ui.error "\nQuitting..."
    Bundler.ui.trace e
    exit 1
  rescue SystemExit => e
    exit e.status
  rescue Exception => e

    Bundler.ui.error <<-EOS
#{'――― MARKDOWN TEMPLATE ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――'}
### Report
* What did you do?
* What did you expect to happen?
* What happened instead?

#{Bundler::Env.new.report(:print_gemfile => false)}

### Error
```
#{e.class} - #{e.message}
#{e.backtrace.join("\n")}
```
#{'――― TEMPLATE END ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――'}
[!] Oh no, an error occurred.

Troubleshooting documentation: http://bit.ly/bundler-issues

Search for existing github issues similar to yours:
#{issues_url(e)}

If none exists, create a ticket, with the template displayed above, on:
https://github.com/bundler/bundler/issues/new
Be sure to first read the contributing guide for details on how to properly submit a ticket:
https://github.com/bundler/bundler/blob/master/CONTRIBUTING.md
You may also include your Gemfile sample.
Don't forget to anonymize any private data!
EOS
    exit 1
  end

  def self.issues_url(exception)
    message = pathless_exception_message(exception.message)
    'https://github.com/bundler/bundler/search?q=' \
    "#{CGI.escape(message)}&type=Issues"
  end

  def self.pathless_exception_message(message)
    message.gsub(/- \(.*\):/, '-')
  end


end
