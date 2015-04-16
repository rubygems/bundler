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

    def ignorable_dependency?(dep)
      dep.type == :development || dep.name == @name
    end

    def dependencies_installed?(specs)
      installed_specs = specs.reject(&:installed?).map(&:name)
      already_installed = lambda {|dep| installed_specs.include? dep.name }
      dependencies.all? {|d| already_installed[d] }
    end

    def dependencies
      @dependencies ||= all_dependencies.reject {|dep| ignorable_dependency? dep }
    end

    def all_dependencies
      @spec.dependencies
    end
  end

  def self.call(*args)
    new(*args).call
  end

  def self.max_threads
    [Bundler.settings[:jobs].to_i-1, 1].max
  end

  def initialize(installer, all_specs, size, standalone, force)
    @installer = installer
    @size = size
    @standalone = standalone
    @force = force
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
      message = @installer.install_gem_from_spec spec_install.spec, @standalone, worker_num, @force
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
    @specs.select(&:ready_to_enqueue?).each do |spec|
      if spec.dependencies_installed? @specs
        worker_pool.enq spec
        spec.state = :enqueued
      end
    end
  end
end
