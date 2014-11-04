vendor = File.expand_path('../vendor/Molinillo-0.1.0/lib', __FILE__)
loaded = $:.include?(vendor)
$:.unshift(vendor) unless loaded
require 'molinillo'
$:.delete(vendor) unless loaded
