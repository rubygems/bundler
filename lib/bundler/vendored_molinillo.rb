vendor = File.expand_path('../vendor/Molinillo-0.2.1/lib', __FILE__)
loaded = $:.include?(vendor)
$:.unshift(vendor) unless loaded
require 'molinillo'
$:.delete(vendor) unless loaded
