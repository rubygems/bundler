# frozen_string_literal: true
module Spec
  module Manpages
    def self.setup
      man_path = Spec::Path.root.join("man")
      return if man_path.children(false).select {|file| file.extname == ".ronn" }.all? do |man|
        man_path.join(man).sub_ext(".txt").file?
      end

      system(Spec::Path.root.join("bin", "rake").to_s, "man:build") || raise("Failed building man pages")
    end
  end
end
