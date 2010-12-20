require "spec_helper"
describe "bundle cache with git" do
  it "base_name should parse scp style URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "git@github.com:repo.git")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with SSH URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "ssh://user@host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with Git URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "git://host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with HTTP URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "http://host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with HTTPS URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "https://host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with FTP URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "ftp://host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with FTPS URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "ftps://host.xz:port/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with RSYNC URI syntax" do
    source  = Bundler::Source::Git.new("uri" => "rsync://host.xz/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with SSH URI syntax with username expansion" do
    source  = Bundler::Source::Git.new("uri" => "ssh://user@host.xz:port/~user/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with Git URI syntax with username expansion" do
    source  = Bundler::Source::Git.new("uri" => "git://host.xz:port/~user/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with SCP URI syntax with username expansion" do
    source  = Bundler::Source::Git.new("uri" => "user@host.xz:/~user/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with File URI syntax with hostname" do
    source  = Bundler::Source::Git.new("uri" => "file://host.name.org/path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
  it "base_name should parse a Git repository location described with File URI syntax without hostname" do
    source  = Bundler::Source::Git.new("uri" => "file:///path/to/repo.git/")
    source.send(:base_name).should == "repo"
  end
end


