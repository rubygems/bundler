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
      # $stderr.puts "------------------------------------------------------------------------------------------"
      # $stderr.puts "[config.rb] Calling #run with args = #{@args}"

      peek = args.shift

      if peek && peek =~ /^\-\-/
        name = args.shift
        scope = $'
      else
        name = peek
        scope = "global"
      end

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

        new_value = args.join(" ")
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

        new_value = new_value.gsub("--global", "").gsub("--local", "").strip

        # $stderr.puts "[config.rb] In #run; just about to resolve conflicts."

        return if resolve_system_path_conflicts(name, new_value, scope) == :conflict

        # $stderr.puts "[config.rb] In #run; system path conflict resolved."
        return if resolve_with_without_conflicts(name, new_value, scope) == :conflict
        modify_with_or_without(name, new_value, scope)
        new_value.gsub!(/\s+/, ":") if name == "with" || name == "without" # Should this come before or after the conflict resolution?

        # $stderr.puts "[config.rb] After conflict resolution: new_value is #{new_value}"

        if name.match(/\Alocal\./)
          pathname = Pathname.new(args.join(" "))
          new_value = pathname.expand_path.to_s if pathname.directory?
        end

        # $stderr.puts "[config.rb] Calling Bundler.settings.send('set_#{scope}', '#{name}', '#{new_value}')"
        Bundler.settings.send("set_#{scope}", name, new_value)
        # $stderr.puts "[config.rb] Done; now Bundler.settings is #{Bundler.settings.inspect}"
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

    def resolve_with_without_conflicts(name, new_value, scope = "global")
      # Note: the group includes the scope, so we don't need to explicitly
      #       differentiate between scopes.
      # FIXME: We can check the size of without (1 or not 1) instead of
      #        storing the difference in a var

      # $stderr.puts "[config.rb] [resolve_with_without_conflicts] Starting method\tname is #{name}\tnew_value is #{new_value}\tscope is #{scope}"

      unless new_value =~ /\-\-local/ or new_value =~ /\-\-global/
        new_value = "#{new_value} --global"
      end

      # $stderr.puts "[config.rb] [resolve_with_without_conflicts] Checkpoint 1"

      new_value = new_value.gsub("--global", "").gsub("--local", "").strip

      # new_value.gsub!("--global", "")
      # new_value.gsub!("--local", "")
      # new_value.strip!

      # $stderr.puts "[config.rb] [resolve_with_without_conflicts] Checkpoint 2"

      group = new_value.to_sym

      # $stderr.puts "[config.rb] [resolve_with_without_conflicts] Checkpoint 3"

      # $stderr.puts "[config.rb] group: #{group}"
      # $stderr.puts "[config.rb] Bundler.settings.inspect: #{Bundler.settings.inspect}"

      # $stderr.puts "[config.rb] Just about to resolve a conflict! name is #{name}\tBundler.settings.with is #{Bundler.settings.with}\tgroup is #{group}"
      # $stderr.puts "[config.rb]"
      # $stderr.puts "[config.rb] Bundler.settings.with(:global) is #{Bundler.settings.with(:global)}"
      # $stderr.puts "[config.rb] Bundler.settings.with(:local) is #{Bundler.settings.with(:local)}"
      # $stderr.puts "[config.rb] Bundler.settings.with is #{Bundler.settings.with}"

      # BACK FROM BREAK: edit this to do the proper with/without group check
      if (name == "with") && (Bundler.settings.without.include? group)

        # TODO: include the scopes of the old setting in the messages below
        Bundler.ui.info "`with` and `without` settings cannot share groups. "\
         "You have already set `without #{new_value}`, so it will be unset."
        difference = Bundler.settings.without - [group]

        if difference == []
          delete_config("without", scope)
        else
          Bundler.settings.without = difference
        end

        :conflict
      elsif (name == "without") && (Bundler.settings.with.include? group)

        Bundler.ui.info "`with` and `without` settings cannot share groups. "\
         "You have already set `with #{new_value}`, so it will be unset."
        Bundler.settings.with = Bundler.settings.with - [group]
        difference = Bundler.settings.with - [group]

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

    def parse_with_without_settings(name, new_value, scope = "global")
      # FIXME: implement
      []
    end

    def modify_with_or_without(name, new_value, scope = "global")
      delete_config(name, nil) if new_value == "" and (name == "with" or name == "without")
    end

    def delete_config(name, scope = nil)
      Bundler.settings.set_local(name, nil) unless scope == "global"
      Bundler.settings.set_global(name, nil) unless scope == "local"
    end
  end
end
