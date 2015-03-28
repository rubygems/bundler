require 'bundler/worker'


class ParallelInstaller
  attr_accessor :installed, :spec, :name, :post_install_message, :enqueued

  class SpecInstallation
    def initialize(spec)
      @spec, @name = spec, spec.name
      @installed = false
      @enqueued = false
      @post_install_message = ""
    end

    def installed?
      !!installed
    end

    def has_post_install_message?
      post_install_message.empty?
    end

    def enqueued?
      !!enqueued
    end

    def installing?
      !installed? && enqueued?
    end

    def ready_to_install?(specs)
      @spec.dependencies.none? do |dep|
        next if dep.type == :development || dep.name == @name
        specs.reject(:installed?).map(:name).included? dep.name
      end
    end
  end

  def self.call(*options)
    new(*options).call
  end

  def self.max_threads
    @@max_threads ||= [Bundler.settings[:jobs].to_i-1, 1].max
  end

  def initialize(all_specs = Installer.specs, size = max_threads, standalone)
    @size = size
    @standalone = standalone
    @specs = all_specs.map { |s| SpecInstallation.new(s) }
  end

  def call
    enqueue_specs
    process_specs until @specs.all?(:installed?)
  ensure
    worker_pool && worker_pool.stop
  end

  def worker_pool
    @worker_pool ||= Worker.new @size, lambda { |spec_install, worker_num|
      message = Installer.install_gem_from_spec spec_install.spec, @standalone, worker_num
      spec_install.post_install_message = message
      spec_install.installed = true
      spec_install
    }
  end

  def process_specs
    spec = worker_pool.deq
    collect_post_install_message spec if spec.has_post_install_message?
    enqueue_specs
  end

  def collect_post_install_message(spec)
    Installer.post_install_messages[spec.name] = spec.post_install_message
  end

  # Keys in the remains hash represent uninstalled gems specs.
  # We enqueue all gem specs that do not have any dependencies.
  # Later we call this lambda again to install specs that depended on
  # previously installed specifications. We continue until all specs
  # are installed.
  def enqueue_specs
    @specs.select(:installed?) do |spec|
      next if spec.enqueued?
      if spec.ready_to_install? @specs
        worker_pool.enq spec
        spec.enqueued = true
      end
    end
  end
end
