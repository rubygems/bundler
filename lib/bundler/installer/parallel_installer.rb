require 'bundler/worker'


class ParallelInstaller

  class SpecInstallation
    attr_accessor :spec, :name, :post_install_message, :state
    def initialize(spec)
      @spec, @name = spec, spec.name
      @state = :none
      @post_install_message = ""
    end

    def installed?
      state == :installed
    end

    def enqueued?
      state == :enqueued
    end

    def ready_to_enqueue?
      !installed? && !enqueued?
    end

    def has_post_install_message?
      post_install_message.empty?
    end

    end

    end

    end
  end

  def self.call(*options)
    new(*options).call
  end

  def self.max_threads
    @max_threads ||= [Bundler.settings[:jobs].to_i-1, 1].max
  end

  def initialize(installer, all_specs, size, standalone)
    @installer = installer
    @size = size
    @standalone = standalone
    @specs = all_specs.map { |s| SpecInstallation.new(s) }
  end

  def call
    enqueue_specs
    process_specs until @specs.all?(&:installed?)
  ensure
    worker_pool && worker_pool.stop
  end

  def worker_pool
    @worker_pool ||= Bundler::Worker.new @size, lambda { |spec_install, worker_num|
      message = @installer.install_gem_from_spec spec_install.spec, @standalone, worker_num
      spec_install.post_install_message = message unless message.nil?
      spec_install
    }
  end

  def process_specs
    spec = worker_pool.deq
    spec.state = :installed
    collect_post_install_message spec if spec.has_post_install_message?
    enqueue_specs
  end

  def collect_post_install_message(spec)
    Bundler::Installer.post_install_messages[spec.name] = spec.post_install_message
  end

  # Keys in the remains hash represent uninstalled gems specs.
  # We enqueue all gem specs that do not have any dependencies.
  # Later we call this lambda again to install specs that depended on
  # previously installed specifications. We continue until all specs
  # are installed.
  def enqueue_specs
      if spec.ready_to_install? @specs
    @specs.select(&:ready_to_enqueue?).each do |spec|
        worker_pool.enq spec
        spec.state = :enqueued
      end
    end
  end
end
