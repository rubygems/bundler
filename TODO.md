## Bundler TODO list

  - Cache Git repositories
  - Build options
  - A gem shit list
  - Interactive mode for bundle (install) to work out conflicts
  - bundle irb / bundle ruby / bundle [whatever] -> bundle exec
  - Generate a bundle stub into the application
  - bundle install --production
    - (recommend symlinking vendor/bundle to a shared location for perf)
    - defaults to bundle install vendor/bundle --disable-shared-gems
    - if vendor/cache exists, defaults to --local
    - disallow modifications to Gemfile.lock
