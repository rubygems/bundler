require "spec_helper"

describe "bundle install with deprecated features" do
  before :each do
    in_app_root
  end

  it "reports that lib is an invalid option" do
    gemfile <<-G
      gem "rack", :lib => "rack"
    G

    bundle :install
    expect(out).to match(/You passed :lib as an option for gem 'rack', but it is invalid/)
  end

end

describe "bundle install to a dead symlink" do
  before do
    in_app_root do
      `ln -s /tmp/idontexist bundle`
    end
  end

  it "reports the symlink is dead" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    bundle "install --path bundle"
    expect(out).to match(/invalid symlink/)
  end
end

describe "invalid or inaccessible gem source" do
  it "can be retried" do
    gemfile <<-G
      source "file://#{gem_repo_missing}"
      gem "rack"
      gem "signed_gem"
    G
    bundle "install", :retry => 2
    exp = Regexp.escape("Retrying source fetch due to error (2/3)")
    expect(out).to match(exp)
    exp = Regexp.escape("Retrying source fetch due to error (3/3)")
    expect(out).to match(exp)
  end
end