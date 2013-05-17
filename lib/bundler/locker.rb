module Bundler
  class Locker < Environment

    # Begins the resolution process for Bundler.
    # For more information see the #run method on this class.
    def self.lock(root, definition, options = {})
      locker = new(root, definition)
      locker.run(options)
      locker
    end


    # Resolves the gem dependencies for the given gemfile and writes
    # out the lock.
    def run(options)
      resolve(options)
      lock
    end


    def resolve(options)
      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
      else
        # We can resolve the definition using remote specs
        unless already_resolved?( options )
          options["local"] ?
          @definition.resolve_with_cache! :
            @definition.resolve_remotely!
        end
      end
    end


    private
    def already_resolved?(options)
      if Bundler.default_lockfile.exist? && !options["update"]
        Bundler.ui.silence do
          begin
            tmpdef = Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
            true unless tmpdef.new_platform? || tmpdef.missing_specs.any?
          rescue BundlerError
          end
        end
      end
    end


  end
end
