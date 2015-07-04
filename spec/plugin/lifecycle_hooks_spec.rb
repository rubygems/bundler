require "spec_helper"

describe "bundler lifecycle plugin" do
  before :each do
    build_gem "bundler-foo", :to_system => true do |s|
      main = <<-EOF
class BundlerCustomLifecycle < Bundler.plugin("1")
  name "Custom lifecycle plugin"
  lifecycle ["before_install", "after_install"] do
    require "lifecycle"
    Lifecycle
  end
end
      EOF
      lifecycle = <<-EOF
class Lifecycle < Bundler.plugin("1", :lifecycle)

  def initialize
  end

  def run(hook_name, args)
    puts "running "+hook_name.to_s
  end
end
      EOF

      s.write("lib/bundler-foo.rb", main)
      s.write("lib/lifecycle.rb", lifecycle)

    end
    bundle "plugin install foo"

  end

  it "before_install and after_install hooks" do
    install_gemfile <<-G
      gem "bundler"
    G
    expect(out).to include("running before_install")
    expect(out).to include("running after_install")
  end


end
