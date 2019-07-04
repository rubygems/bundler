# frozen_string_literal: true

module Spec
  module Manpages
    def self.setup
      system(Spec::Path.root.join("bin", "rake").to_s, "man:build") || raise("Failed building man pages")
    end
  end
end
