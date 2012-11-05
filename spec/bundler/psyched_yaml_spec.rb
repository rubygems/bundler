require 'spec_helper'

describe YamlSyntaxError do
  it "is raised on YAML parse errors" do
    expect{ YAML.parse "{foo" }.to raise_error(YamlSyntaxError)
  end
end
