class CertificateManager
  BUNDLER_CERTIFICATES_PATH = "lib/bundler/ssl_certs/"
  LOCAL_RUBYGEMS_PATH = "tmp/rubygems"
  RUBYGEMS_CERTIFICATES_PATH = "#{File.join(LOCAL_RUBYGEMS_PATH, 'lib/rubygems/ssl_certs/')}"
  CERTIFICATE_FILE_EXTENSION = ".pem"

  attr_reader :bundler_certificates, :rubygems_certificates

  def initialize
    @bundler_certificates = certificate_files(BUNDLER_CERTIFICATES_PATH)
    @rubygems_certificates = certificate_files(RUBYGEMS_CERTIFICATES_PATH)
  end

  def up_to_date?
    same_filenames = (bundler_certificates == rubygems_certificates)
    same_certificates = false

    if same_filenames
      same_certificates = bundler_certificates.all? do |filename|
        FileUtils.compare_file(File.join(BUNDLER_CERTIFICATES_PATH, filename), File.join(RUBYGEMS_CERTIFICATES_PATH, filename))
      end
    end

    same_filenames && same_certificates
  end

  def update!
    unless up_to_date?
      FileUtils.rm Dir.glob(File.join(BUNDLER_CERTIFICATES_PATH, "*#{CERTIFICATE_FILE_EXTENSION}"))
      FileUtils.cp_r Dir.glob(File.join(RUBYGEMS_CERTIFICATES_PATH, "*#{CERTIFICATE_FILE_EXTENSION}")), BUNDLER_CERTIFICATES_PATH
    end
  end

  private

  def certificate_files(path)
    Dir.entries(path).select do |filename|
      filename.end_with?(CERTIFICATE_FILE_EXTENSION)
    end.sort
  end
end
