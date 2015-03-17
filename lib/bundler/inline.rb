def gemfile(install = false, &blk)
  require 'bundler'
  old_root = Bundler.method(:root)
  def Bundler.root
    Pathname.pwd.expand_path
  end
  ENV['BUNDLE_GEMFILE'] ||= 'Gemfile'

  builder = Bundler::Dsl.new
  builder.instance_eval(&blk)
  definition = builder.to_definition(nil, true)
  def definition.lock(file); end
  definition.validate_ruby!
  Bundler::Installer.install(Bundler.root, definition, :system => true) if install
  runtime = Bundler::Runtime.new(nil, definition)
  runtime.setup_environment
  runtime.setup.require

  bundler_module = class << Bundler; self; end
  bundler_module.send(:define_method, :root, old_root)
end
