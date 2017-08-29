# frozen_string_literal: true

module Bundler
  class CLI::Config
    attr_reader :name, :value, :options, :scope, :thor

    def initialize(options, name, value, thor)
      @options = options
      @name = name
      value = Array(value)
      @value = value.empty? ? nil : value.join(" ")
      @thor = thor
      validate_scope!
    end

    def run
      unless name
        confirm_all
        return
      end

      if options[:delete]
        if !@explicit_scope || scope != "global"
          Bundler.settings.set_local(name, nil)
        end
        if !@explicit_scope || scope != "local"
          Bundler.settings.set_global(name, nil)
        end
        return
      end

      if value.nil?
        if options[:parseable]
          if value = Bundler.settings[name]
            Bundler.ui.info("#{name}=#{value}")
          end
          return
        end

        confirm(name)
        return
      end

      Bundler.ui.info(message) if message
      Bundler.settings.send("set_#{scope}", name, new_value)
    end

  private

    def confirm_all
      if @options[:parseable]
        thor.with_padding do
          Bundler.settings.all.each do |setting|
            val = Bundler.settings[setting]
            Bundler.ui.info "#{setting}=#{val}"
          end
        end
      else
        Bundler.ui.confirm "Settings are listed in order of priority. The top value will be used.\n"
        Bundler.settings.all.each do |setting|
          Bundler.ui.confirm "#{setting}"
          show_pretty_values_for(setting)
          Bundler.ui.confirm ""
        end
      end
    end

    def confirm(name)
      Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
      show_pretty_values_for(name)
    end

    def new_value
      pathname = Pathname.new(value)
      if name.start_with?("local.") && pathname.directory?
        pathname.expand_path.to_s
      else
        value
      end
    end

    def message
      locations = Bundler.settings.locations(name)
      if @options[:parseable]
        "#{name}=#{new_value}" if new_value
      elsif scope == "global"
        if !locations[:local].nil?
          "Your application has set #{name} to #{locations[:local].inspect}. " \
            "This will override the global value you are currently setting"
        elsif locations[:env]
          "You have a bundler environment variable for #{name} set to " \
            "#{locations[:env].inspect}. This will take precedence over the global value you are setting"
        elsif !locations[:global].nil? && locations[:global] != value
          "You are replacing the current global value of #{name}, which is currently " \
            "#{locations[:global].inspect}"
        end
      elsif scope == "local" && !locations[:local].nil? && locations[:local] != value
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

    def validate_scope!
      @explicit_scope = true
      scopes = %w[global local]
      scopes.reject! {|s| options[s].nil? }
      case scopes.size
      when 0
        @scope = "global"
        @explicit_scope = false
      when 1
        @scope = scopes.first
      else
        raise InvalidOption,
          "The options #{scopes.join " and "} were specified. Please only use one of the switches at a time."
      end
    end
  end
end
