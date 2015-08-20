module Bundler
  class CLI::Config
    attr_reader :options, :thor
    attr_accessor :args

    def initialize(options, args, thor)
      @options = options
      @args = args
      @thor = thor
    end

    def run
      peek = args.shift

      name = (peek && peek =~ /^\-\-/) ? args.shift : peek
      scope = @options["local"] ? "local" : "global"

      unless name
        Bundler.ui.confirm "Settings are listed in order of priority. The top value will be used.\n"

        Bundler.settings.all.each do |setting|
          Bundler.ui.confirm "#{setting}"
          thor.with_padding do
            Bundler.settings.pretty_values_for(setting).each do |line|
              Bundler.ui.info line
            end
          end
          Bundler.ui.confirm ""
        end
        return
      end

      case scope
      when "delete"
        delete_config(name)
      when "local", "global"
        if args.empty?
          Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
          thor.with_padding do
            Bundler.settings.pretty_values_for(name).each {|line| Bundler.ui.info line }
          end
          return
        end

        new_value = args.join(" ").gsub("--global", "").gsub("--local", "").strip
        new_value.gsub!(/\s+/, ":") if name == "with" || name == "without"
        locations = Bundler.settings.locations(name)

        if scope == "global"
          if locations[:local]
            Bundler.ui.info "Your application has set #{name} to #{locations[:local].inspect}. " \
              "This will override the global value you are currently setting"
          end

          if locations[:env]
            Bundler.ui.info "You have a bundler environment variable for #{name} set to " \
              "#{locations[:env].inspect}. This will take precedence over the global value you are setting"
          end

          if locations[:global] && locations[:global] != new_value
            Bundler.ui.info "You are replacing the current global value of #{name}, which is currently " \
              "#{locations[:global].inspect}"
          end
        end

        if scope == "local" && locations[:local] != new_value
          Bundler.ui.info "You are replacing the current local value of #{name}, which is currently " \
            "#{locations[:local].inspect}"
        end

        return if resolve_system_path_conflicts(name, new_value, scope) == :conflict
        resolve_group_conflicts(name, new_value, scope)
        delete_config(name, nil) if new_value == "" and (name == "with" or name == "without")

        # NOTE: Bundler.settings stores multiple with and without keys, given an array like
        # [:foo, :bar, :baz, :qux], as "foo:bar:baz:qux" (see #set_array)

        if name.match(/\Alocal\./)
          pathname = Pathname.new(args.join(" "))
          new_value = pathname.expand_path.to_s if pathname.directory?
        end

        Bundler.settings.send("set_#{scope}", name, new_value)
      else
        Bundler.ui.error "Invalid scope --#{scope} given. Please use --local or --global."
        exit 1
      end
    end

    def resolve_system_path_conflicts(name, new_value, scope = "global")
      if name == "path.system" and Bundler.settings[:path] and new_value == "true"
        Bundler.ui.warn "`path` is already configured, so it will be unset."
        delete_config("path")
        :conflict
      elsif name == "path" and Bundler.settings["path.system"]
        Bundler.ui.warn "`path.system` is already configured, so it will be unset."
        delete_config("path.system")
        :conflict
      else
        :no_conflict
      end
    end

    def resolve_group_conflicts(name, new_value, scope = "global")
      groups = new_value.split(":").map(&:to_sym)

      if (name == "with") && without_conflict?(groups, scope)
        # FIXME: Simplify without_scope, conflicts, and with_scopes
        without_scope = groups_conflict?(:without, groups, :local, scope) ? "locally" : "globally"
        conflicts = conflicting_groups(:without, groups, without_scope == "locally" ? :local : :global, scope)

        Bundler.ui.info "`with` and `without` settings cannot share groups. "\
         "You have already set `without #{conflicts.join(" ")}` #{without_scope}, so it will be unset."
        difference = Bundler.settings.without - groups

        if difference == []
          delete_config("without", scope)
        else
          Bundler.settings.without = difference
        end

        :conflict
      elsif (name == "without") && with_conflict?(groups, scope)
        with_scope = groups_conflict?(:with, groups, :local, scope) ? "locally" : "globally"
        conflicts = conflicting_groups(:with, groups, with_scope == "locally" ? :local : :global, scope)

        Bundler.ui.info "`with` and `without` settings cannot share groups. "\
         "You have already set `with #{conflicts.join(" ")}` #{with_scope}, so it will be unset."
        difference = Bundler.settings.with - groups

        if difference == []
          delete_config("with", scope)
        else
          Bundler.settings.with = difference
        end

        :conflict
      else
        :no_conflict
      end
    end

    def delete_config(name, scope = nil)
      Bundler.settings.set_local(name, nil) unless scope == "global"
      Bundler.settings.set_global(name, nil) unless scope == "local"
    end

    # group_conflict?: Detects conflicts in optional groups in consideration of scope.
    # - `name` is the option name (`with` or `without`).
    # - `groups` is an array of the name(s) of the included or excluded group(s).
    # - `scope_prev` is the scope of the option previously set.
    # - `scope_new` is the scope of the option the user is currently trying to set.
    # NOTE: scope_prev and scope_new must be local or global.
    def groups_conflict?(name, groups, scope_prev, scope_new)
      conflicts = conflicting_groups(name, groups, scope_prev, scope_new)
      # FIXME: Do we need the `&& scope_new.to_sym == scope_prev`?
      conflicts && conflicts.size > 0 && scope_new.to_sym == scope_prev
    end

    def conflicting_groups(name, groups, scope_prev, scope_new)
      settings = Bundler.settings.send(name.to_sym, scope_prev)
      settings = (settings.map {|opt| opt.to_s.split(":").map(&:to_sym) }).flatten # TODO: refactor
      groups & settings
    end

    def without_conflict?(group, scope)
      groups_conflict?(:without, group, :local, scope) or groups_conflict?(:without, group, :global, scope)
    end

    def with_conflict?(group, scope)
      groups_conflict?(:with, group, :local, scope) or groups_conflict?(:with, group, :global, scope)
    end
  end
end
