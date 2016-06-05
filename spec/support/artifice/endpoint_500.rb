# frozen_string_literal: true
require File.expand_path("../../path.rb", __FILE__)
include Spec::Path

$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/artifice*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/rack-*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/rack-*/lib")].last}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/tilt*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/sinatra*/lib")].first}"

require "artifice"
require "sinatra/base"

Artifice.deactivate

class Endpoint500 < Sinatra::Base
  before do
    halt 500
  end
end

Artifice.activate_with(Endpoint500)
