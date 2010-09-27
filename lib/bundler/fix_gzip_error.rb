require 'gem/package/tar_input'

# monkey patch that clears the problem where bundler 
# barfs out saying "not in gzip format" whilst reading 
# gemspecs from inside a gem.  silly that this works, 
# but it does :)
class Gem::Package::TarInput
  
  # there's probably a more focused way to do this, 
  # where poking at one particular attribute in the
  # entry takes care of the problem we've seen.  If
  # anyone would like to troubleshoot that, that'd 
  # be welcome.  
  def zipped_stream_with_gzip_fix(entry)
    entry.inspect
    zipped_stream_without_gzip_fix(entry)
  end
  alias_method_chain :zipped_stream, :gzip_fix
  
end