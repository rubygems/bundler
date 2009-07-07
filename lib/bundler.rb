require "rubygems"
require "rubygems/remote_fetcher"
require "pp"

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
}.map {|k,v| Gem::Dependency.new(k, v)}

require File.expand_path(File.join(File.dirname(__FILE__), "..", "gem_resolver", "lib", "gem_resolver"))
pp GemResolver.resolve(list, index).all_specs.map {|x| x.full_name }

puts "TOTAL: #{Time.now - t}"

# deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{Gem.sources.first}/Marshal.4.8.Z"); nil
# inflated = Gem.inflate deflated; nil
# index    = Marshal.load(inflated); nil
# File.open("dumped", "w") do |f|
#   f.puts inflated
# end