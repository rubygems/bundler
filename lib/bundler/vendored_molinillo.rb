vendor = File.expand_path('../vendor/Molinillo-double-backjumping/lib', __FILE__)
loaded = $:.include?(vendor)
$:.unshift(vendor) unless loaded
require 'molinillo'
$:.delete(vendor) unless loaded
