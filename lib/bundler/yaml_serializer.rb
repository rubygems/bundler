# frozen_string_literal: true

module Bundler
  # A stub yaml serializer that can handle only hashes and strings (as of now).
  module YAMLSerializer
  module_function

    def dump(hash)
      yaml = String.new("---")
      yaml << dump_hash(hash)
    end

    def dump_hash(hash)
      yaml = String.new("\n")
      hash.each do |k, v|
        yaml << k << ":"
        if v.is_a?(Hash)
          yaml << dump_hash(v).gsub(/^(?!$)/, "  ") # indent all non-empty lines
        else
          yaml << " " << v.to_s.gsub(/\s+/, " ").inspect << "\n"
        end
      end
      yaml
    end

    SCAN_REGEX = /
      ^
      ([ ]*) # indentations
      (.*) # key
      (?::(?=\s)) # :  (without the lookahead the #key includes this when : is present in value)
      [ ]?
      (?: !\s)? # optional exclamation mark found with ruby 1.9.3
      (['"]?) # optional opening quote
      (.*) # value
      \3 # matching closing quote
      $
    /xo

    def load(str)
      res = {}
      stack = [res]
      str.scan(SCAN_REGEX).each do |(indent, key, _, val)|
        depth = indent.scan(/  /).length
        if val.empty?
          new_hash = {}
          stack[depth][key] = new_hash
          stack[depth + 1] = new_hash
        else
          stack[depth][key] = val
        end
      end
      res
    end

    class << self
      private :dump_hash
    end
  end
end
