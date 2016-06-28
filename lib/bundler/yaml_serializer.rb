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
        elsif v.is_a?(Array) # Expected to be array of strings
          yaml << "\n- " << v.map {|s| s.to_s.gsub(/\s+/, " ").inspect }.join("\n- ") << "\n"
        else
          yaml << " " << v.to_s.gsub(/\s+/, " ").inspect << "\n"
        end
      end
      yaml
    end

    ARRAY_REGEX = /
      ^
      ([ ]*) # indentations
      (?:-[ ]) # '- ' before array items
      (['"]?) # optional opening quote
      (.*) # value
      \2 # matching closing quote
      $
    /xo

    HASH_REGEX = /
      ^
      ([ ]*) # indentations
      (.*) # key
      (?::(?=(?:\s|$))) # :  (without the lookahead the #key includes this when : is present in value)
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
      str.split("\n").each do |line|
        if line =~ HASH_REGEX
          indent, key, _, val = HASH_REGEX.match(line).captures
          key = convert_to_backward_compatible_key(key)
          depth = indent.scan(/  /).length
          if val.empty?
            new_hash = {}
            stack[depth][key] = new_hash
            stack[depth + 1] = new_hash
          else
            stack[depth][key] = val
          end
        end
      end
      res
    end

    # for settings' keys
    def convert_to_backward_compatible_key(key)
      key = "#{key}/" if key =~ /https?:/i && key !~ %r{/\Z}
      key = key.gsub(".", "__") if key.include?(".")
      key
    end

    class << self
      private :dump_hash, :convert_to_backward_compatible_key
    end
  end
end
