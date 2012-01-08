module Bundler
  module Config
    DATA_DIR = File.expand_path('../../../data',__FILE__)

    TEMPLATES = File.join(DATA_DIR,'bundler','templates')
  end
end
