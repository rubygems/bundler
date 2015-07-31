require File.expand_path("../../path.rb", __FILE__)
require File.expand_path("../../../../lib/bundler/deprecate", __FILE__)
include Spec::Path

# Set up pretend http gem server with FakeWeb
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/artifice*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/rack-*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/rack-*/lib")].last}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/tilt*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/sinatra*/lib")].first}"
$LOAD_PATH.unshift "#{Dir[base_system_gems.join("gems/compact_index*/lib")].first}"
require "artifice"
require "compact_index"
require "sinatra/base"

class CompactIndexAPI < Sinatra::Base
  helpers do
    def load_spec(name, version, platform, gem_repo)
      full_name = "#{name}-#{version}"
      full_name += "-#{platform}" if platform != "ruby"
      Marshal.load(Gem.inflate(File.open(gem_repo.join("quick/Marshal.4.8/#{full_name}.gemspec.rz")).read))
    end

    def etag_response
      body = yield
      checksum = Digest::MD5.hexdigest(body)
      headers "ETag" => checksum
      if checksum == request.env["HTTP_IF_NONE_MATCH"]
        status 304
        return ""
      else
        content_type 'text/plain'
        ranges = Rack::Utils.byte_ranges(env, body.bytesize)
        return body unless ranges
        status 206
        ranges.map! do |range|
          body.byteslice(range)
        end.join
      end
    rescue => e
      puts e
      puts e.backtrace
      raise
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
      file = tmp('versions.list')
      file.delete if file.file?
      file = CompactIndex::VersionsFile.new(file.to_path)
      versions = gems.group_by { |s| s[:name] }
      file.update_with(versions)
      CompactIndex.versions(file, [])
    end
  end

  get "/info/:name" do
    etag_response do
      specs = gems.select { |s| s[:name] == params[:name] }
      CompactIndex.info(specs).tap { |i| puts i }
    end
  end

  get "/quick/Marshal.4.8/:id" do
    redirect "/fetch/actual/gem/#{params[:id]}"
  end

  get "/fetch/actual/gem/:id" do
    File.read("#{gem_repo1}/quick/Marshal.4.8/#{params[:id]}")
  end

  get "/gems/:id" do
    File.read("#{gem_repo1}/gems/#{params[:id]}")
  end

  get "/specs.4.8.gz" do
    File.read("#{gem_repo1}/specs.4.8.gz")
  end

  get "/prerelease_specs.4.8.gz" do
    File.read("#{gem_repo1}/prerelease_specs.4.8.gz")
  end
end

Artifice.activate_with(CompactIndexAPI)
