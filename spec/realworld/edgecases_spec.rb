describe "real world edgecases", :realworld => true do
  if RUBY_VERSION < "1.9"
    # there is no rbx-relative-require gem that will install on 1.9
    it "ignores extra gems with bad platforms" do
      install_gemfile <<-G
        source :rubygems
        gem "linecache", "0.46"
      G
      err.should eq("")
    end
  end
end
