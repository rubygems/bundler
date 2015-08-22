class Bundler::CompactIndexClient
  class Cache
    attr_reader :directory

    def initialize(directory)
      @directory = Pathname.new(directory).expand_path
      FileUtils.mkdir_p dependencies_path(nil)
    end

    def names
      lines(names_path)
    end

    def names_path
      directory + "names"
    end

    def versions
      versions_by_name = Hash.new {|hash, key| hash[key] = [] }
      info_checksums_by_name = {}
      lines(versions_path).map do |line|
        next if line == "-1"
        name, versions_string, info_checksum = line.split(" ", 3)
        info_checksums_by_name[name] = info_checksum || ""
        versions_by_name[name].concat(versions_string.split(",").map! do |version|
          version.split("-", 2).unshift(name)
        end)
      end
      [versions_by_name, info_checksums_by_name]
    end

    def versions_path
      directory + "versions"
    end

    def dependencies(name)
      lines(dependencies_path(name)).map do |line|
        parse_gem(line)
      end
    end

    def dependencies_path(name)
      directory + "dependencies" + name.to_s
    end

    def specific_dependency(name, version, platform)
      pattern = [version, platform].compact.join("-")
      matcher = /\A#{Regexp.escape(pattern)}\b/ unless pattern.empty?
      lines(dependencies_path(name)).each do |line|
        return parse_gem(line) if line =~ matcher
      end if matcher
      nil
    end

  private

    def lines(path)
      return [] unless path.file?
      lines = path.read.lines
      header = lines.index("---\n")
      lines = header ? lines[header + 1..-1] : lines
      lines.each(&:strip!)
    end

    def parse_gem(string)
      version_and_platform, rest = string.split(" ", 2)
      version, platform = version_and_platform.split("-", 2)
      dependencies, requirements = rest.split("|", 2).map {|s| s.split(",") } if rest
      dependencies = dependencies ? dependencies.map {|d| parse_dependency(d) } : []
      requirements = requirements ? requirements.map {|r| parse_dependency(r) } : []
      [version, platform, dependencies, requirements]
    end

    def parse_dependency(string)
      dependency = string.split(":")
      dependency[-1] = dependency[-1].split("&")
      dependency
    end
  end
end
