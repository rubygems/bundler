# frozen_string_literal: true

require "simplecov"

module SimpleCov
  class SourceFile
    def project_filename
      @filename.sub(Regexp.new("^#{Regexp.escape(SimpleCov.root)}"), "")
    end
  end
end
