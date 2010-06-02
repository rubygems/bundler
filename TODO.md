## Bundler TODO list

  - Implement Gemfile API to describe gem platform requirements
  - Check to make sure ~/.bundler/bin is in $PATH
  - Cache Git repositories
  - Interactive mode for bundle (install) to work out conflicts
  - bundle irb / bundle ruby / bundle [whatever] -> bundle exec
  - Make bundle (install) work when sudo might be needed
  - Generate a bundle stub into the application

  - SpecSet#for should be smart about platforms since it could
    have invalid platforms in the set.
