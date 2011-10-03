describe "real world edgecases", :realworld => true do
  it "ignores extra gems with bad platforms" do
    install_gemfile <<-G
      source :rubygems
      gem "linecache"
    G
    err.should eq("")
  end
end