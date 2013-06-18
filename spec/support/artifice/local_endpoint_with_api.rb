require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

module ApiDependencies
  def self.dependencies_for(gem_names, repo_path)
    return [] if gem_names.nil? || gem_names.empty?
    read_dependencies(gem_names, repo_path, "specs.4.8") # + read_dependencies(gem_names, repo_path, "prerelease_specs.4.8")
  end

  def self.read_dependencies(gem_names, repo_path, index_file)
    marshal_file = File.join(repo_path, index_file)
    return [] unless File.exists?(marshal_file)

    require 'rubygems'
    require 'bundler'
    Bundler::Deprecate.skip_during do
      Marshal.load(File.open(marshal_file).read).map do |name, version, platform|
        spec = load_spec(name, version, platform, repo_path)
        if gem_names.include?(spec.name)
          rv = {
            :name         => spec.name,
            :number       => spec.version.version,
            :platform     => spec.platform.to_s,
            :dependencies => spec.dependencies.select {|dep| dep.type == :runtime }.map do |dep|
              [dep.name, dep.requirement.requirements.map {|a| a.join(" ") }.join(", ")]
            end
          }
          rv
        end
      end.compact
    end
  end

  def self.load_spec(name, version, platform, repo_path)
    full_name = "#{name}-#{version}"
    full_name += "-#{platform}" if platform != "ruby"
    Marshal.load(Gem.inflate(File.open(File.join(repo_path, "/quick/Marshal.4.8/#{full_name}.gemspec.rz")).read))
  end
end

class LocalEndpointWithApi < Endpoint
  # Local
  get "/local/quick/Marshal.4.8/:id" do
    redirect "/local/fetch/actual/gem/#{params[:id]}"
  end

  get "/local/fetch/actual/gem/:id" do
    File.read("#{local_gem_repo}/quick/Marshal.4.8/#{params[:id]}")
  end

  get "/local/gems/:id" do
    File.read("#{local_gem_repo}/gems/#{params[:id]}")
  end

  get "/local/api/v1/dependencies" do
    gem_list = (params[:gems] || '').split(',')
    deps = Marshal.dump(ApiDependencies.dependencies_for(gem_list, local_gem_repo))
    deps
  end

  get "/local/specs.4.8.gz" do
    File.read("#{local_gem_repo}/specs.4.8.gz")
  end

  get "/local/prerelease_specs.4.8.gz" do
    File.read("#{local_gem_repo}/prerelease_specs.4.8.gz")
  end

  # Upstream
  get "/upstream/quick/Marshal.4.8/:id" do
    redirect "/upstream/fetch/actual/gem/#{params[:id]}"
  end

  get "/upstream/fetch/actual/gem/:id" do
    File.read("#{upstream_gem_repo}/quick/Marshal.4.8/#{params[:id]}")
  end

  get "/upstream/gems/:id" do
    File.read("#{upstream_gem_repo}/gems/#{params[:id]}")
  end

  get "/upstream/api/v1/dependencies" do
    gem_list = (params[:gems] || '').split(',')
    Marshal.dump(ApiDependencies.dependencies_for(gem_list, upstream_gem_repo))
  end

  get "/upstream/specs.4.8.gz" do
    File.read("#{upstream_gem_repo}/specs.4.8.gz")
  end

  get "/upstream/prerelease_specs.4.8.gz" do
    File.read("#{upstream_gem_repo}/prerelease_specs.4.8.gz")
  end
end

Artifice.activate_with(LocalEndpointWithApi)
