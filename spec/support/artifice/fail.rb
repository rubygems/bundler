# frozen_string_literal: true

require File.expand_path("../../path.rb", __FILE__)

# Set up pretend http gem server with FakeWeb
$LOAD_PATH.unshift Dir[Spec::Path.base_system_gems.join("gems/artifice*/lib")].first.to_s
$LOAD_PATH.unshift Dir[Spec::Path.base_system_gems.join("gems/rack-*/lib")].first.to_s
$LOAD_PATH.unshift Dir[Spec::Path.base_system_gems.join("gems/rack-*/lib")].last.to_s
$LOAD_PATH.unshift Dir[Spec::Path.base_system_gems.join("gems/tilt*/lib")].first.to_s
require "artifice"

class Fail
  def call(env)
    raise(exception(env))
  end

  def exception(env)
    name = ENV.fetch("BUNDLER_SPEC_EXCEPTION") { "Errno::ENETUNREACH" }
    const = name.split("::").reduce(Object) {|mod, sym| mod.const_get(sym) }
    const.new("host down: Bundler spec artifice fail! #{env["PATH_INFO"]}")
  end
end
Artifice.activate_with(Fail.new)
