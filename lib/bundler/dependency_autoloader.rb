module Bundler
  module DependencyAutoloader
    @registered_symbols = Hash.new { |h,k| h[k] = [] }
    
    class << self
      
      attr_reader :registered_symbols
      
      # Registers a dependency to be autoloaded for the given symbols.
      # 
      # This will also inject_hooks! if it is required.  We don't want them loaded unless absolutely
      # necessary.
      def register_dependency(runtime, dependency, symbols)
        symbols.each do |symbol|
          registered_symbols[symbol.to_sym] << [runtime, dependency]
        end
        
        inject_hooks!
      end
      
      # Unfortunately, we can't take advantage of Kernel::autoload, as it only supports loading a
      # single file per symbol.  Gotta build our own, which makes this a little fragile.
      # 
      # We only support top-level constants, as we can't predict whether an intermediary constant
      # will be a class/module, and what it might inherit from.
      def inject_hooks!
        return if @injected_hooks
        
        ::Object.class_eval do
          class << self
            orig_const_missing = instance_method :const_missing
            define_method(:const_missing) do |sym|
              if ::Bundler::DependencyAutoloader.registered_symbols.include? sym
                ::Bundler::DependencyAutoloader.registered_symbols[sym].each do |runtime, dependency|
                  runtime.require_dependency(dependency)
                end
                
                # If we made it this far, the require was successful.  Now we need to return the
                # constant to fulfill our contract.
                return Object.const_get(sym) if Object.const_defined?(sym)
              end
              
              orig_const_missing.bind(self).call(sym)
            end
          end
        end
        
        @injected_hooks = true
      end
      
    end
  end
end
