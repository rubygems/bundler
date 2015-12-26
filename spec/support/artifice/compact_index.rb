require File.expand_path("../endpoint", __FILE__)

$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/compact_index*/lib")].first}"
require "compact_index"

class CompactIndexAPI < Endpoint
  helpers do
    def load_spec(name, version, platform, gem_repo)
      full_name = "#{name}-#{version}"
      full_name += "-#{platform}" if platform != "ruby"
      Marshal.load(Gem.inflate(File.open(gem_repo.join("quick/Marshal.4.8/#{full_name}.gemspec.rz")).read))
    end

    def etag_response
      response_body = yield
      checksum = Digest::MD5.hexdigest(response_body)
      return if not_modified?(checksum)
      headers "ETag" => quote(checksum)
      headers "Surrogate-Control" => "max-age=2592000, stale-while-revalidate=60"
      content_type "text/plain"
      requested_range_for(response_body)
    rescue => e
      puts e
      puts e.backtrace
      raise
    end

    def not_modified?(checksum)
      etags = parse_etags(request.env["HTTP_IF_NONE_MATCH"])

      if etags.include?(checksum)
        headers "ETag" => quote(checksum)
        status 304
        body ""
      end
    end

    def requested_range_for(response_body)
      ranges = Rack::Utils.byte_ranges(env, response_body.bytesize)

      if ranges
        status 206
        body ranges.map! {|range| response_body.byteslice(range) }.join
      else
        status 200
        body response_body
      end
    end

    def quote(string)
      '"' << string << '"'
    end

    def parse_etags(value)
      value ? value.split(/, ?/).select {|s| s.sub!(/"(.*)"/, '\1') } : []
    end

    def gems(gem_repo = gem_repo1)
      @gems ||= {}
      @gems[gem_repo] ||= begin
        Bundler::Deprecate.skip_during do
          Marshal.load(File.open(gem_repo.join("specs.4.8")).read).map do |name, version, platform|
            spec = load_spec(name, version, platform, gem_repo)
            {
              :name         => spec.name,
              :number       => spec.version.version,
              :platform     => spec.platform.to_s,
              :dependencies => spec.dependencies.select {|dep| dep.type == :runtime }.map do |dep|
                { :gem => dep.name, :version => dep.requirement.requirements.map {|a| a.join(" ") }.join(", ") }
              end,
              :ruby_version => spec.required_ruby_version,
              :rubygems_version => spec.required_rubygems_version,
              :created_at => spec.date.to_s,
            }
          end
        end
      end
    end
  end

  get "/names" do
    etag_response do
      CompactIndex.names(gems.map(&:name))
    end
  end

  get "/versions" do
    etag_response do
      file = tmp("versions.list")
      file.delete if file.file?
      file = CompactIndex::VersionsFile.new(file.to_path)
      versions = gems.group_by {|s| s[:name] }.map {|n, v| { :name => n, :versions => v } }
      file.update_with(versions)
      CompactIndex.versions(file, nil, {})
    end
  end

  get "/info/:name" do
    etag_response do
      specs = gems.select {|s| s[:name] == params[:name] }
      CompactIndex.info(specs)
    end
  end
end

Artifice.activate_with(CompactIndexAPI)
