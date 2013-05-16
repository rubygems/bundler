require 'rubygems/installer'

module Bundler
  class GemInstaller < Gem::Installer
    def check_executable_overwrite(filename)
      # Bundler needs to install gems regardless of binstub overwriting
    end

    if WINDOWS
      def build_extensions
        # Gain the lock because rubygems use Dir.chdir
        SharedHelpers.chdir('.') do
          super
        end
      end
    end
  end
end
