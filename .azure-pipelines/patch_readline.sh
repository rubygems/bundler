ruby_version=$(ruby -e 'puts RUBY_VERSION')

git apply --ignore-space-change --ignore-whitespace '.azure-pipelines\rbreadline.diff' --directory="C:/hostedtoolcache/windows/Ruby/$ruby_version/x64/lib/ruby/site_ruby" --unsafe-paths
