require "bundler" # The error lives here

describe Bundler::Fetcher::Index do
  it "handles Net::HTTPFatalErrors" do
    rubygems = double(:sources => [], "sources=" => [])
    expect(rubygems).to receive(:fetch_all_remote_specs) {
      raise Net::HTTPFatalError.new("nooo", 404)
    }
    allow(Bundler).to receive(:rubygems).and_return(rubygems)
    allow(Bundler).to receive(:ui).and_return(double(:trace => nil))

    expect {
      Bundler::Fetcher::Index.new(nil, nil, nil).specs(%w[foo bar])
    }.to raise_error(Bundler::HTTPError)
  end
end
