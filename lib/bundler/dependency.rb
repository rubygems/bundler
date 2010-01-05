module Bundler
  class InvalidEnvironmentName < StandardError; end

  class Dependency < Gem::Dependency
    attr_reader :name, :version, :require_as, :only, :except
    attr_accessor :source

    def initialize(name, options = {}, &block)
      options.each do |k, v|
        options[k.to_s] = v
      end

      super(name, options["version"] || ">= 0")

      @require_as = options["require_as"]
      @only       = options["only"]
      @except     = options["except"]
      @source     = options["source"]
      @block      = block

      if (@only && @only.include?("rubygems")) || (@except && @except.include?("rubygems"))
        raise InvalidEnvironmentName, "'rubygems' is not a valid environment name"
      end
    end

    def in?(environment)
      environment = environment.to_s

      return false unless !@only || @only.include?(environment)
      return false if @except && @except.include?(environment)
      true
    end

    def require_env(environment)
      return unless in?(environment)

      if @require_as
        Array(@require_as).each { |file| require file }
      else
        begin
          require name
        rescue LoadError
          # Do nothing
        end
      end

      @block.call if @block
    end

    def no_bundle?
      source == SystemGemSource.instance
    end

    def ==(o)
      [name, version, require_as, only, except] ==
        [o.name, o.version, o.require_as, o.only, o.except]
    end

    alias version version_requirements

  end
end
