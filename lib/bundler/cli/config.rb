# frozen_string_literal: true
module Bundler
  class CLI::Config
    attr_reader :name, :options, :scope, :thor
    attr_accessor :args

    def initialize(options, args, thor)
      @options = options
      @args = args
      @thor = thor
      @name = peek = args.shift
      @scope = "global"
      return unless peek && peek.start_with?("--")
      @name = args.shift
      @scope = peek[2..-1]
    end

    def run
      unless name
        confirm_all
        return
      end

      unless valid_scope?(scope)
        Bundler.ui.error "Invalid scope --#{scope} given. Please use --local or --global."
        exit 1
      end

      if scope == "delete"
        Bundler.settings.set_local(name, nil)
        Bundler.settings.set_global(name, nil)
        return
      end

      if args.empty?
        confirm(name)
        return
      end

      Bundler.ui.info(message) if message
      Bundler.settings.send("set_#{scope}", name, new_value)
    end

  private

    def confirm_all
      Bundler.ui.confirm "Settings are listed in order of priority. The top value will be used.\n"
      Bundler.settings.all.each do |setting|
        Bundler.ui.confirm "#{setting}"
        show_pretty_values_for(setting)
        Bundler.ui.confirm ""
      end
    end

    def confirm(name)
      Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
      show_pretty_values_for(name)
    end

    def new_value
      pathname = Pathname.new(args.join(" "))
      if name.start_with?("local.") && pathname.directory?
        pathname.expand_path.to_s
      else
        args.join(" ")
      end
    end

    def message
      locations = Bundler.settings.locations(name)
      if scope == "global"
        if locations[:local]
          "Your application has set #{name} to #{locations[:local].inspect}. " \
            "This will override the global value you are currently setting"
        elsif locations[:env]
          "You have a bundler environment variable for #{name} set to " \
            "#{locations[:env].inspect}. This will take precedence over the global value you are setting"
        elsif locations[:global] && locations[:global] != args.join(" ")
          "You are replacing the current global value of #{name}, which is currently " \
            "#{locations[:global].inspect}"
        end
      elsif scope == "local" && locations[:local] != args.join(" ")
        "You are replacing the current local value of #{name}, which is currently " \
          "#{locations[:local].inspect}"
      end
    end

    def show_pretty_values_for(setting)
      thor.with_padding do
        Bundler.settings.pretty_values_for(setting).each do |line|
          Bundler.ui.info line
        end
      end
    end

    def valid_scope?(scope)
      %w(delete local global).include?(scope)
    end

    # Clears `path` if `path.system` is being set, and vice versa.
    #
    # @param  [String] name
    #         the name of the option being set by the user.
    #
    # @param  [String] new_value
    #         the value of the option being set by the user.
    #
    # @param  [String] scope
    #         the scope of the option being set by the user (either `"local"` or
    #         `"global"`).
    def resolve_system_path_conflicts(name, new_value, scope = "global")
      if name == "path.system" and Bundler.settings[:path] and new_value == "true"
        Bundler.ui.warn "`path` is already configured, so it will be unset."
        delete_config("path")
      elsif name == "path" and Bundler.settings["path.system"]
        Bundler.ui.warn "`path.system` is already configured, so it will be unset."
        delete_config("path.system")
      end
    end

    # Check whether `with` or `without` groups have already been configured by
    # the user. If so, check whether the user is setting a `without` or `with`
    # group which conflicts with the previously set value in the appropriate
    # scope. If there is a conflict, a warning including the conflicting
    # group(s) is printed, and the previously set conflicting value is unset.
    #
    # Example: If `--local without foo bar baz` is set, and the user runs
    # `bundle config --local with foo qux`, there will be a conflict, because
    # `foo` is in the local `with` and `without` groups. If instead
    # `bundle config --global with foo qux` is run, there will not be a
    # conflict, because `foo` is in the local `without` group but the global
    # `with` group.
    #
    # See config_spec.rb for other examples.
    #
    # @param  [String] name
    #         the name of the option being set by the user.
    #
    # @param  [String] new_value
    #         the value of the option being set by the user.
    #
    # @param  [String] scope
    #         the scope of the option being set by the user (either `"local"` or
    #         `"global"`).
    #
    # @return [Symbol] Either `:conflict` or `:no_conflict`, depending on whether
    #         the options conflict.
    #
    def resolve_group_conflicts(name, new_value, scope = "global")
      groups = new_value.split(":").map(&:to_sym)

      if (name == "with") && without_conflict?(groups, scope)
        without_scope = groups_conflict?(:without, groups, :local, scope) ? "locally" : "globally"
        conflicts = conflicting_groups(:without, groups, without_scope == "locally" ? :local : :global, scope)

        Bundler.ui.info "`with` and `without` settings cannot share groups. "\
         "You have already set `without #{conflicts.join(" ")}` #{without_scope}, so it will be unset."
        difference = Bundler.settings.without - groups

        if difference == []
          delete_config("without", scope)
        else
          Bundler.settings.local_without = difference
        end
      elsif scope == "local" && locations[:local] != args.join(" ")
        "You are replacing the current local value of #{name}, which is currently " \
          "#{locations[:local].inspect}"
      end
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
          Bundler.settings.local_with = difference
        end

        :conflict
      else
        :no_conflict
      end
    end

    # Deletes (sets to `nil`) the given configuration variable within the
    # given scope. If the scope is `"global"`, only the local value is deleted,
    # and vice versa. If the scope is `nil` or anything else, both the local
    # and global values are unset. Note that we do not delete the current config
    # since it is not used in #run or any conflict resolution and current
    # configurations are not persisted between commands.
    #
    # @param  [String] name
    #         the name of the option being deleted.
    #
    # @param  [String] scope
    #         the scope of the option being deleted (either `"local"` or
    #         `"global"`).
    #
    # @return [Nil] The new value of `name`, which is `nil`.
    #
    def delete_config(name, scope = nil)
      Bundler.settings.set_local(name, nil) unless scope == "global"
      Bundler.settings.set_global(name, nil) unless scope == "local"
    end

    # Detects conflicts in `with` and `without` groups in consideration of
    # scope. Checks that the intersection of the two groups is nonempty and that
    # the two groups have the same scope.
    #
    # @param  [String] name
    #         the name (either `"with"` or `"without"`) of the already set group
    #         with which we're comparing the user's groups.
    #
    # @param  [Array<Symbol>] groups
    #         the name(s) of the included or excluded group(s) which the user is
    #         trying to set.
    #
    # @param  [Symbol] scope_prev
    #         the scope of the option previously set (either `:local` or `:global`).
    #
    # @param  [String] scope_new
    #         the scope of the option the user is currently trying to set (either
    #         `"local"` or `"global"`).
    #
    # @return [Boolean] Whether the `with` and `without` groups conflict.
    #
    def groups_conflict?(name, groups, scope_prev, scope_new)
      conflicts = conflicting_groups(name, groups, scope_prev, scope_new)
      conflicts && conflicts.size > 0 && scope_new.to_sym == scope_prev
    end

    # Finds the conflicting (overlapping) groups in the list given by the user
    # and those already stored in `Bundler.settings`.
    #
    # @param  [String] name
    #         the name (either `"with"` or `"without"`) of the already set group
    #         with which we're comparing the user's groups.
    #
    # @param  [Array<Symbol>] groups
    #         the name(s) of the included or excluded group(s) which the user is
    #         trying to set.
    #
    # @param  [Symbol] scope_prev
    #         the scope of the option previously set (either `:local` or `:global`).
    #
    # @param  [String] scope_new
    #         the scope of the option the user is currently trying to set (either
    #         `"local"` or `"global"`).
    #
    # @return [Array<Symbol>] An array of the conflicting groups.
    #
    def conflicting_groups(name, groups, scope_prev, scope_new)
      settings = Bundler.settings.send(name.to_sym, scope_prev)
      settings = (settings.map {|opt| opt.to_s.split(":").map(&:to_sym) }).flatten # TODO: refactor
      groups & settings
    end

    # Determines whether the user's (`with`) groups conflict with the previously
    # set `without` groups in `Bundler.settings`.
    #
    # @param  [Array<Symbol>] groups
    #         the name(s) of the group(s) which the user is trying to set.
    #
    # @param  [String] scope
    #         the scope of the option the user is currently trying to set (either
    #         `"local"` or `"global"`).
    #
    # @return [Boolean] Whether there's a conflict in either the `local` or
    #         `global` scope.
    #
    def without_conflict?(groups, scope)
      groups_conflict?(:without, groups, :local, scope) or groups_conflict?(:without, groups, :global, scope)
    end

    # Determines whether the user's (`without`) groups conflict with the
    # previously set `with` groups in `Bundler.settings`.
    #
    # @param  [Array<Symbol>] groups
    #         the name(s) of the group(s) which the user is trying to set.
    #
    # @param  [String] scope
    #         the scope of the option the user is currently trying to set (either
    #         `"local"` or `"global"`).
    #
    # @return [Boolean] Whether there's a conflict in either the `local` or
    #         `global` scope.
    #
    def with_conflict?(groups, scope)
      groups_conflict?(:with, groups, :local, scope) or groups_conflict?(:with, groups, :global, scope)
    end
  end
end
