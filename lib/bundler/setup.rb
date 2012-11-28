require 'bundler/shared_helpers'

fail = lambda do |e|
  puts "\e[31m#{e.message}\e[0m"
  puts e.backtrace.join("\n") if ENV["DEBUG"]
  if Bundler::GemNotFound === e
    puts "\e[33mRun `bundle install` to install missing gems.\e[0m"
  end
  exit e.status_code
end

if Bundler::SharedHelpers.in_bundle?
  require 'bundler'
  if STDOUT.tty?
    begin
      Bundler.setup
    rescue Bundler::BundlerError => e
      if ENV["TRY_TO_BUNDLE"]
        ENV["TRY_TO_BUNDLE"] = nil
        puts "trying to bundle ..."
        if Bundler.with_clean_env{ system("bundle") }
          Bundler.clear_gemspec_cache
          begin
            Bundler.setup
          rescue Bundler::BundlerError => e
            fail(e)
          end
        else
          fail.call(e)
        end
      else
        fail.call(e)
      end
    end
  else
    Bundler.setup
  end

  # Add bundler to the load path after disabling system gems
  bundler_lib = File.expand_path("../..", __FILE__)
  $LOAD_PATH.unshift(bundler_lib) unless $LOAD_PATH.include?(bundler_lib)
end
