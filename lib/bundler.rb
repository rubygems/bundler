require "rubygems"
require "rubygems/remote_fetcher"
require "pp"

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

class FasterSourceIndex
  def initialize(index)
    @index = index
    @new_index = Hash.new {|h,k| h[k] = {}}
    @index.gems.values.each do |spec|
      @new_index[spec.name][spec.version] = spec
    end
    @results = {}
  end

  def search(dependency)
    @results[dependency.hash] ||= begin
      possibilities = @new_index[dependency.name].values
      possibilities.select do |spec|
        dependency =~ spec
      end.sort_by {|s| s.version }
    end
  end
end

index = nil
File.open("dumped", "r") do |f|
  index = Marshal.load(f.read)
end

index = FasterSourceIndex.new(index)

t = Time.now

# ENV["GEM_RESOLVER_DEBUG"] = "true"

list = {
  "merb-core" => ">= 0",
  "merb-haml" => ">= 0",
  "merb_datamapper" => ">= 0"

  # "merb-core" => "1.0.12",
  # "merb-haml" => "1.0.12",
  # "merb_datamapper" => "1.0.12"
}.map {|k,v| Gem::Dependency.new(k, v)}

require File.expand_path(File.join(File.dirname(__FILE__), "..", "gem_resolver", "lib", "gem_resolver"))
pp GemResolver.resolve(list, index).all_specs.map {|x| x.full_name }

puts "TOTAL: #{Time.now - t}"

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