class Object
  def gem_resolver_inspect
    inspect
  end
end

class Gem::Specification
  def gem_resolver_inspect
    "#<Spec: #{full_name}>"
  end
end

class Gem::Dependency
  def gem_resolver_inspect
    "#<Dep: #{to_s}>"
  end
end

class Array
  def gem_resolver_inspect
    '[' + map {|x| x.gem_resolver_inspect}.join(", ") + ']'
  end
end

require 'set'
class Set
  def gem_resolver_inspect
    to_a.gem_resolver_inspect
  end
end

class Hash
  def gem_resolver_inspect
    '{' + map {|k,v| "#{k.gem_resolver_inspect} => #{v.gem_resolver_inspect}"}.join(", ") + '}'
  end
end

class String
  def gem_resolver_inspect
    inspect
  end
end

