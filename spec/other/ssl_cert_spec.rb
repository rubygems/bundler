require_relative '../../lib/bundler/ssl_certs/certificate_manager'

describe "SSL Certificates" do
  it "are up to date with Rubygems" do
    manager = CertificateManager.new
    expect(manager).to be_up_to_date
  end
end
