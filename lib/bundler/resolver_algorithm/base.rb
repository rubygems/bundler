module Bundler
  module ResolverAlgorithm
    class Base
      include SafeCatch
      extend SafeCatch

      def initialize(index, source_requirements, base)
        @errors               = {}
        @stack                = []
        @base                 = base
        @index                = index
        @deps_for             = {}
        @missing_gems         = Hash.new(0)
        @source_requirements  = source_requirements
        @iteration_counter    = 0
        @started_at           = Time.now
      end

      # to be overridden by child classes
      def start(requirements); end

      def debug
        if ENV['DEBUG_RESOLVER']
          debug_info = yield
          debug_info = debug_info.inspect unless debug_info.is_a?(String)
          $stderr.puts debug_info
        end
      end

      def gems_size(dep)
        search(dep).size
      end

      def clear_search_cache
        @deps_for = {}
      end

      def successify(activated)
        activated.values.map { |s| s.to_specs }.flatten.compact
      end

      def search(dep)
        if base = @base[dep.name] and base.any?
          reqs = [dep.requirement.as_list, base.first.version.to_s].flatten.compact
          d = Gem::Dependency.new(base.first.name, *reqs)
        else
          d = dep.dep
        end

        @deps_for[d.hash] ||= search_in_gem_index(dep, d)
      end

      def clean_req(req)
        if req.to_s.include?(">= 0")
          req.to_s.gsub(/ \(.*?\)$/, '')
        else
          req.to_s.gsub(/\, (runtime|development)\)$/, ')')
        end
      end

      def version_conflict
        VersionConflict.new(errors.keys, error_message)
      end

      # For a given conflicted requirement, print out what exactly went wrong
      def gem_message(requirement)
        m = ""

        # A requirement that is required by itself is actually in the Gemfile, and does
        # not "depend on" itself
        if requirement.required_by.first && requirement.required_by.first.name != requirement.name
          m << "    #{clean_req(requirement.required_by.first)} depends on\n"
          m << "      #{clean_req(requirement)}\n"
        else
          m << "    #{clean_req(requirement)}\n"
        end
        m << "\n"
      end

      def error_message
        errors.inject("") do |o, (conflict, (origin, requirement))|

          # origin is the SpecSet of specs from the Gemfile that is conflicted with
          if origin

            o << %{Bundler could not find compatible versions for gem "#{origin.name}":\n}
            o << "  In Gemfile:\n"

            o << gem_message(requirement)

            # If the origin is "bundler", the conflict is us
            if origin.name == "bundler"
              o << "  Current Bundler version:\n"
              other_bundler_required = !requirement.requirement.satisfied_by?(origin.version)
              # If the origin is a LockfileParser, it does not respond_to :required_by
            elsif !origin.respond_to?(:required_by) || !(origin.required_by.first)
              o << "  In snapshot (Gemfile.lock):\n"
            end

            o << gem_message(origin)

            # If the bundle wants a newer bundler than the running bundler, explain
            if origin.name == "bundler" && other_bundler_required
              o << "This Gemfile requires a different version of Bundler.\n"
              o << "Perhaps you need to update Bundler by running `gem install bundler`?"
            end

            # origin is nil if the required gem and version cannot be found in any of
            # the specified sources
          else

            # if the gem cannot be found because of a version conflict between lockfile and gemfile,
            # print a useful error that suggests running `bundle update`, which may fix things
            #
            # @base is a SpecSet of the gems in the lockfile
            # conflict is the name of the gem that could not be found
            if locked = @base[conflict].first
              o << "Bundler could not find compatible versions for gem #{conflict.inspect}:\n"
              o << "  In snapshot (Gemfile.lock):\n"
              o << "    #{clean_req(locked)}\n\n"

              o << "  In Gemfile:\n"
              o << gem_message(requirement)
              o << "Running `bundle update` will rebuild your snapshot from scratch, using only\n"
              o << "the gems in your Gemfile, which may resolve the conflict.\n"

              # the rest of the time, the gem cannot be found because it does not exist in the known sources
            else
              if requirement.required_by.first
                o << "Could not find gem '#{clean_req(requirement)}', which is required by "
                o << "gem '#{clean_req(requirement.required_by.first)}', in any of the sources."
              else
                o << "Could not find gem '#{clean_req(requirement)} in any of the sources\n"
              end
            end

          end
          o
        end
      end

      private
      def search_in_gem_index(dep, d)
        index = @source_requirements[d.name] || @index
        results = index.search(d, @base[d.name])
        if results.any?
          version = results.first.version
          nested  = [[]]
          results.each do |spec|
            if spec.version != version
              nested << []
              version = spec.version
            end
            nested.last << spec
          end
          deps = nested.map{|a| Bundler::Resolver::SpecGroup.new(a) }.select{|sg| sg.for?(dep.__platform) }
        else
          deps = []
        end
      end

      # Indicates progress by writing a '.' every iteration_rate time which is
      # aproximately every second. iteration_rate is calculated in the first
      # second of resolve running.
      def indicate_progress
        @iteration_counter += 1

        if iteration_rate.nil?
          if ((Time.now - started_at) % 3600).round >= 1
            @iteration_rate = iteration_counter
          end
        else
          if ((iteration_counter % iteration_rate) == 0)
            Bundler.ui.info ".", false
          end
        end
      end

    end
  end
end
