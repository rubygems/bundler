## Bundler TODO list

  - Check to make sure ~/.bundler/bin is in $PATH
  - Cache Git repositories
  - Interactive mode for bundle (install) to work out conflicts
  - bundle irb / bundle ruby / bundle [whatever] -> bundle exec
  - Make bundle (install) work when sudo might be needed
  - Generate a bundle stub into the application
  - Handle the following case (no remote fetching):
    1) Depend on nokogiri, nokogiri is installed locally (ruby platform)
    2) Run bundle package. nokogiri-1.4.2.gem is cached
    3) Clone on jruby
    4) Run `bundle install`
    Bundler will happily install the RUBY platform nokogiri because it
    is cached and bundler has not hit the remote source once so it does
    not know that there is a nokogiri-1.4.2-java.gem available