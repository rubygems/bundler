vendor = File.expand_path('../vendor/thor-0.19.1/lib', __FILE__)
loaded = $:.include?(vendor)
$:.unshift(vendor) unless loaded
require 'thor'
require 'thor/actions'
