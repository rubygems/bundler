require "rubygems"
require "rubygems/remote_fetcher"
require "pp"

# $time = 0
# 
# module Bundler
#   class LazySourceIndex
#     
#     def initialize
#       @cache = Hash.new
#       @cache_two = Hash.new do |h,(gem_info,uri)|
#         puts "FETCHING: #{gem_info}"
#         h[[gem_info,uri]] = Gem::SpecFetcher.fetcher.fetch_spec(gem_info, URI.parse(uri))
#       end
#     end
#     
#     def search(gem_pattern, platform_only = false)
#       start = Time.now
#       retval = @cache[gem_pattern.hash] ||= begin
#         Gem::SpecFetcher.fetcher.find_matching(gem_pattern, true, true).map do |result|
#           @cache_two[result]
#         end
#       end
#       $time += Time.now - start
#       retval
#     end
#     
#   end
# end

# index = Bundler::LazySourceIndex.new
# pp index.search(Gem::Dependency.new("merb-core", "> 0"))

# time = Time.now
# deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{Gem.sources.first}/Marshal.4.8.Z"); nil
# inflated = Gem.inflate deflated; nil
# index    = Marshal.load(inflated); nil
# File.open("dumped", "w") do |f|
#   f.puts inflated
# end
# puts "FINISHED INFLATING: #{Time.now - time}s"

p 1

index = nil
File.open("dumped", "r") do |f|
  index = Marshal.load(f.read)
end

p 2

t = Time.now

new_index = Hash.new {|h,k| h[k] = {}}
index.gems.values.each do |spec|
  new_index[spec.name][spec.version] = spec
end

puts "DONE in #{Time.now - t}"

p new_index["merb-core"][Gem::Version.new("1.0.12")]

# require File.expand_path(File.join(File.dirname(__FILE__), "..", "gem_resolver", "lib", "gem_resolver"))
# ENV["GEM_RESOLVER_DEBUG"] = "true"

# require "ruby-prof"
# 
# RubyProf.start
# 
# resolved = GemResolver.resolve([Gem::Dependency.new("rails", "> 0")], index)
# 
# result = RubyProf.stop
# 
# printer = RubyProf::GraphPrinter.new(result)
# printer.print
# 
# pp resolved.all_specs.map {|x| [x.name, x.version]}

# Gem::SpecFetcher.fetcher.find_matching(dependency) returns
#   [[["merb-core", #<Gem::Version "1.0.12">, "ruby"], "http://gems.rubyforge.org/"]]
#
# Gem::SpecFetcher.fetcher.fetch_spec(["merb-core", Gem::Version.new("0.9.2"), "ruby"], URI.parse("http://gems.rubyforge.org/"))
#   Gem::Specification