module Bundler
  class Source
    class LocalRubygems < Rubygems

      def specs
        @specs ||= begin
          idx = super
          idx.use(cached_specs, :override_dupes) if @allow_cached || @allow_remote
          idx.use(installed_specs, :override_dupes)
          idx
        end
      end

    end
  end
end
