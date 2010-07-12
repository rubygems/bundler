module Spec
  module Sudo
    def self.present?
      @which_sudo ||= `which sudo`.strip
      !@which_sudo.empty? && ENV['BUNDLER_SUDO_TESTS']
    end

    def test_sudo?
      Sudo.present?
    end

    def sudo(cmd)
      raise "sudo not present" unless Sudo.present?
      sys_exec("sudo #{cmd}")
    end

    def chown_system_gems_to_root
      sudo "chown -R root #{system_gem_path}"
    end
  end
end