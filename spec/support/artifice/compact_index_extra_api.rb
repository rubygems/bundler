require File.expand_path("../compact_index", __FILE__)

Artifice.deactivate

class CompactIndexExtraApi < CompactIndexAPI
  get "/extra/names" do
    etag_response do
      CompactIndex.names(gems(gem_repo4).map(&:name))
    end
  end

  get "/extra/versions" do
    etag_response do
      file = tmp("versions.list")
      file.delete if file.file?
      file = CompactIndex::VersionsFile.new(file.to_path)
      versions = gems(gem_repo4).group_by {|s| s[:name] }
      file.update_with(versions)
      CompactIndex.versions(file, [])
    end
  end

  get "/extra/info/:name" do
    etag_response do
      specs = gems(gem_repo4).select {|s| s[:name] == params[:name] }
      CompactIndex.info(specs)
    end
  end

  get "/extra/specs.4.8.gz" do
    File.read("#{gem_repo4}/specs.4.8.gz")
  end

  get "/extra/prerelease_specs.4.8.gz" do
    File.read("#{gem_repo4}/prerelease_specs.4.8.gz")
  end

  get "/extra/quick/Marshal.4.8/:id" do
    redirect "/extra/fetch/actual/gem/#{params[:id]}"
  end

  get "/extra/fetch/actual/gem/:id" do
    File.read("#{gem_repo4}/quick/Marshal.4.8/#{params[:id]}")
  end

  get "/extra/gems/:id" do
    File.read("#{gem_repo4}/gems/#{params[:id]}")
  end
end

Artifice.activate_with(CompactIndexExtraApi)
