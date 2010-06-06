module Spec
  module Sudo
    def self.sudo?
      @which_sudo ||= `which sudo`.strip
      !@which_sudo.empty?
    end

    module Describe
      def describe_sudo(*args, &blk)
        return unless Sudo.sudo?
        describe(*args) do
          before :each do
            pending "sudo tests are broken"
            chown_system_gems
          end

          instance_eval(&blk)
        end
      end
    end

    def self.included(klass)
      klass.extend Describe
    end

    def sudo?
      Sudo.sudo?
    end

    def sudo(cmd)
      cmd = "sudo #{cmd}" if sudo?
      sys_exec(cmd)
    end

    def chown_system_gems
      sudo "chown -R root #{system_gem_path}"
    end
  end
end