require "pathname"
require "set"
require "bundler/worker"

class Bundler::CompactIndexClient
  require "bundler/vendor/compact_index_client/lib/compact_index_client/cache"
  require "bundler/vendor/compact_index_client/lib/compact_index_client/updater"
  require "bundler/vendor/compact_index_client/lib/compact_index_client/version"

  attr_reader :directory

  def initialize(directory, fetcher)
    @directory = Pathname.new(directory)
    @updater = Updater.new(fetcher)
    @cache = Cache.new(@directory)
    @endpoints = Set.new
    @info_checksums_by_name = {}
  end

  def names
    update(@cache.names_path, "names")
    @cache.names
  end

  def versions
    update(@cache.versions_path, "versions")
    versions, @info_checksums_by_name = @cache.versions
    versions
  end

  def dependencies(names, pool_size = 25)
    update = Proc.new {|name, _| update_info(name); name }
    worker = Bundler::Worker.new(pool_size, update)
    names.each {|name| worker.enq(name) }

    names.map do
      name = worker.deq
      @cache.dependencies(name).map {|d| d.unshift(name) }
    end.flatten(1)
  end

  def spec(name, version, platform = nil)
    update_info(name)
    @cache.specific_dependency(name, version, platform)
  end

  def update_and_parse_checksums!
    return @info_checksums_by_name if @parsed_checksums
    update(@cache.versions_path, "versions")
    @info_checksums_by_name = @cache.checksums
    @parsed_checksums = true
  end

private

  def update(local_path, remote_path)
    return if @endpoints.include?(remote_path)
    @updater.update(local_path, url(remote_path))
    @endpoints << remote_path
  end

  def update_info(name)
    path = @cache.info_path(name)
    checksum = @updater.checksum_for_file(path)
    return if checksum && checksum == @info_checksums_by_name[name]
    update(path, "info/#{name}")
  end

  def url(path)
    path
  end
end
