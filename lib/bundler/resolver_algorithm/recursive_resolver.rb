module Bundler
  module ResolverAlgorithm
    class RecursiveResolver < Base
      attr_reader :errors, :started_at, :iteration_rate, :iteration_counter
      def start(reqs)
        activated = {}
        @gems_size = Hash[reqs.map { |r| [r, gems_size(r)] }]

        resolve(reqs, activated)
      end

      def resolve(reqs, activated, depth = 0)
        # If the requirements are empty, then we are in a success state. Aka, all
        # gem dependencies have been resolved.
        safe_throw :success, successify(activated) if reqs.empty?

        indicate_progress

        debug { print "\e[2J\e[f" ; "==== Iterating ====\n\n" }

        # Sort dependencies so that the ones that are easiest to resolve are first.
        # Easiest to resolve is defined by:
        #   1) Is this gem already activated?
        #   2) Do the version requirements include prereleased gems?
        #   3) Sort by number of gems available in the source.
        reqs = reqs.sort_by do |a|
          [ activated[a.name] ? 0 : 1,
            a.requirement.prerelease? ? 0 : 1,
            @errors[a.name]   ? 0 : 1,
            activated[a.name] ? 0 : @gems_size[a] ]
        end

        debug { "Activated:\n" + activated.values.map {|a| "  #{a}" }.join("\n") }
        debug { "Requirements:\n" + reqs.map {|r| "  #{r}"}.join("\n") }

        activated = activated.dup

        # Pull off the first requirement so that we can resolve it
        current = reqs.shift

        $stderr.puts "#{' ' * depth}#{current}" if ENV['DEBUG_RESOLVER_TREE']

        debug { "Attempting:\n  #{current}"}

        # Check if the gem has already been activated, if it has, we will make sure
        # that the currently activated gem satisfies the requirement.
        existing = activated[current.name]
        if existing || current.name == 'bundler'
          # Force the current
          if current.name == 'bundler' && !existing
            existing = search(DepProxy.new(Gem::Dependency.new('bundler', VERSION), Gem::Platform::RUBY)).first
            raise GemNotFound, %Q{Bundler could not find gem "bundler" (#{VERSION})} unless existing
            existing.required_by << existing
            activated['bundler'] = existing
          end

          if current.requirement.satisfied_by?(existing.version)
            debug { "    * [SUCCESS] Already activated" }
            @errors.delete(existing.name)
            # Since the current requirement is satisfied, we can continue resolving
            # the remaining requirements.

            # I have no idea if this is the right way to do it, but let's see if it works
            # The current requirement might activate some other platforms, so let's try
            # adding those requirements here.
            dependencies = existing.activate_platform(current.__platform)
            reqs.concat dependencies

            dependencies.each do |dep|
              next if dep.type == :development
              @gems_size[dep] ||= gems_size(dep)
            end

            resolve(reqs, activated, depth + 1)
          else
            debug { "    * [FAIL] Already activated" }
            @errors[existing.name] = [existing, current]
            debug { current.required_by.map {|d| "      * #{d.name} (#{d.requirement})" }.join("\n") }
            # debug { "    * All current conflicts:\n" + @errors.keys.map { |c| "      - #{c}" }.join("\n") }
            # Since the current requirement conflicts with an activated gem, we need
            # to backtrack to the current requirement's parent and try another version
            # of it (maybe the current requirement won't be present anymore). If the
            # current requirement is a root level requirement, we need to jump back to
            # where the conflicting gem was activated.
            parent = current.required_by.last
            # `existing` could not respond to required_by if it is part of the base set
            # of specs that was passed to the resolver (aka, instance of LazySpecification)
            parent ||= existing.required_by.last if existing.respond_to?(:required_by)
            # We track the spot where the current gem was activated because we need
            # to keep a list of every spot a failure happened.
            if parent && parent.name != 'bundler'
              debug { "    -> Jumping to: #{parent.name}" }
              required_by = existing.respond_to?(:required_by) && existing.required_by.last
              safe_throw parent.name, required_by && required_by.name
            else
              # The original set of dependencies conflict with the base set of specs
              # passed to the resolver. This is by definition an impossible resolve.
              raise version_conflict
            end
          end
        else
          # There are no activated gems for the current requirement, so we are going
          # to find all gems that match the current requirement and try them in decending
          # order. We also need to keep a set of all conflicts that happen while trying
          # this gem. This is so that if no versions work, we can figure out the best
          # place to backtrack to.
          conflicts = Set.new

          # Fetch all gem versions matching the requirement
          matching_versions = search(current)

          # If we found no versions that match the current requirement
          if matching_versions.empty?
            # If this is a top-level Gemfile requirement
            if current.required_by.empty?
              if base = @base[current.name] and !base.empty?
                version = base.first.version
                message = "You have requested:\n" \
                  "  #{current.name} #{current.requirement}\n\n" \
                  "The bundle currently has #{current.name} locked at #{version}.\n" \
                  "Try running `bundle update #{current.name}`"
              elsif current.source
                name = current.name
                versions = @source_requirements[name][name].map { |s| s.version }
                message  = "Could not find gem '#{current}' in #{current.source}.\n"
                if versions.any?
                  message << "Source contains '#{name}' at: #{versions.join(', ')}"
                else
                  message << "Source does not contain any versions of '#{current}'"
                end
              else
                message = "Could not find gem '#{current}' "
                if @index.source_types.include?(Bundler::Source::Rubygems)
                  message << "in any of the gem sources listed in your Gemfile."
                else
                  message << "in the gems available on this machine."
                end
              end
              raise GemNotFound, message
              # This is not a top-level Gemfile requirement
            else
              @errors[current.name] = [nil, current]
            end
          end

          matching_versions.reverse_each do |spec_group|
            conflict = resolve_requirement(spec_group, current, reqs.dup, activated.dup, depth)
            conflicts << conflict if conflict
          end

          # We throw the conflict up the dependency chain if it has not been
          # resolved (in @errors), thus avoiding branches of the tree that have no effect
          # on this conflict.  Note that if the tree has multiple conflicts, we don't
          # care which one we throw, as long as we get out safe
          if !current.required_by.empty? && !conflicts.empty?
            @errors.reverse_each do |req_name, pair|
              if conflicts.include?(req_name)
                # Choose the closest pivot in the stack that will affect the conflict
                errorpivot = (@stack & [req_name, current.required_by.last.name]).last
                debug { "    -> Jumping to: #{errorpivot}" }
                safe_throw errorpivot, req_name
              end
            end
          end

          # If the current requirement is a root level gem and we have conflicts, we
          # can figure out the best spot to backtrack to.
          if current.required_by.empty? && !conflicts.empty?
            # Check the current "catch" stack for the first one that is included in the
            # conflicts set. That is where the parent of the conflicting gem was required.
            # By jumping back to this spot, we can try other version of the parent of
            # the conflicting gem, hopefully finding a combination that activates correctly.
            @stack.reverse_each do |savepoint|
              if conflicts.include?(savepoint)
                debug { "    -> Jumping to: #{savepoint}" }
                safe_throw savepoint
              end
            end
          end
        end
      end

      def resolve_requirement(spec_group, requirement, reqs, activated, depth)
        # We are going to try activating the spec. We need to keep track of stack of
        # requirements that got us to the point of activating this gem.
        spec_group.required_by.replace requirement.required_by
        spec_group.required_by << requirement

        activated[spec_group.name] = spec_group
        debug { "  Activating: #{spec_group.name} (#{spec_group.version})" }
        debug { spec_group.required_by.map { |d| "    * #{d.name} (#{d.requirement})" }.join("\n") }

        dependencies = spec_group.activate_platform(requirement.__platform)

        # Now, we have to loop through all child dependencies and add them to our
        # array of requirements.
        debug { "    Dependencies"}
        dependencies.each do |dep|
          next if dep.type == :development
          debug { "    * #{dep.name} (#{dep.requirement})" }
          dep.required_by.replace(requirement.required_by)
          dep.required_by << requirement
          @gems_size[dep] ||= gems_size(dep)
          reqs << dep
        end

        # We create a savepoint and mark it by the name of the requirement that caused
        # the gem to be activated. If the activated gem ever conflicts, we are able to
        # jump back to this point and try another version of the gem.
        length = @stack.length
        @stack << requirement.name
        retval = safe_catch(requirement.name) do
          # try to resolve the next option
          resolve(reqs, activated, depth)
        end

        # clear the search cache since the catch means we couldn't meet the
        # requirement we need with the current constraints on search
        clear_search_cache

        # Since we're doing a lot of throw / catches. A push does not necessarily match
        # up to a pop. So, we simply slice the stack back to what it was before the catch
        # block.
        @stack.slice!(length..-1)
        retval
      end

    end
  end
end
