require 'bundler/gem_helper'

module Bundler
  class GemHelperMercurial < GemHelper

    protected
    def hg_push
      perform_hg_push ' --rev .'  #mimic the git only-current-branch-push
      # the above command should push tags also
      Bundler.ui.confirm "Pushed hg commits and tags for the current branch"
    end
    alias :git_push :hg_push

    def perform_hg_push(options = '')
      cmd = "hg push #{options}"
      out, code = sh_with_code(cmd)
      raise "Couldn't hg push. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
    end
    alias :perform_git_push :perform_hg_push


    def guard_already_tagged
      # mercurial tags are outputted in the form:
      # tagname1                local_commit_number:commit_hash
      # tagname2                local_commit_number:commit_hash
      sh('hg tags').split(/\n/).each do |t|
        raise("This tag has already been committed to the repo.") if t.start_with?(version_tag)
      end
    end

    def guard_clean
      clean? or raise("There are files that need to be committed first.")
    end

    def clean?
      sh("hg status -mard").empty?
    end

    def tag_version
      sh "hg tag -m \"Version #{version}\" #{version_tag}"
      Bundler.ui.confirm "Tagged #{version_tag}"
      yield if block_given?
    rescue
      Bundler.ui.error "Untagged #{version_tag} due to error"
      sh_with_code "hg tag --remove #{version_tag}"
      raise
    end
  end
end