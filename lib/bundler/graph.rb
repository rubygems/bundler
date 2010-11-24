module Bundler
  class Graph

    USER_OPTIONS = {:style => 'filled', :fillcolor => '#B9B9D5'}.freeze

    def initialize(env)
      @env = env
    end

    def nodes
      populate
      @nodes
    end

    def groups
      populate
      @groups
    end

    def viz(output_file, show_gem_versions = false, show_dependency_requirements = false)
      require 'graphviz'
      populate

      graph_viz = GraphViz::new('Gemfile', {:concentrate => true, :normalize => true, :nodesep => 0.55})
      graph_viz.edge[:fontname] = graph_viz.node[:fontname] = 'Arial, Helvetica, SansSerif'
      graph_viz.edge[:fontsize] = 12

      viz_nodes = {}

      # populate all of the nodes
      nodes.each do |name, node|
        label = name.dup
        label << "\n#{node.version}" if show_gem_versions
        options = { :label => label }
        options.merge!( USER_OPTIONS ) if node.is_user
        viz_nodes[name] = graph_viz.add_node( name, options )
      end

      group_nodes = {}
      @groups.each do |name, dependencies|
        group_nodes[name] = graph_viz.add_node(name.to_s, { :shape => 'box3d', :fontsize => 16 }.merge(USER_OPTIONS))
        dependencies.each do |dependency|
          options = { :weight => 2 }
          if show_dependency_requirements && (dependency.requirement.to_s != ">= 0")
            options[:label] = dependency.requirement.to_s
          end
          graph_viz.add_edge( group_nodes[name], viz_nodes[dependency.name], options )
        end
      end

      @groups.keys.select { |group| group != :default }.each do |group|
        graph_viz.add_edge( group_nodes[group], group_nodes[:default], { :weight => 2 } )
      end

      viz_nodes.each do |name, node|
        nodes[name].dependencies.each do |dependency|
          options = { }
          if nodes[dependency.name].is_user
            options[:constraint] = false
          end
          if show_dependency_requirements && (dependency.requirement.to_s != ">= 0")
            options[:label] = dependency.requirement.to_s
          end

          graph_viz.add_edge( node, viz_nodes[dependency.name], options )
        end
      end

      graph_viz.output( :png => output_file )
    end

    private

    def populate
      return if @populated

      # hash of name => GraphNode
      @nodes = {}
      @groups = {}

      # Populate @nodes
      @env.specs.each { |spec| @nodes[spec.name] = GraphNode.new(spec.name, spec.version) }

      # For gems in Gemfile, add details
      @env.current_dependencies.each do |dependency|
        next unless node = @nodes[dependency.name]
        node.is_user = true

        dependency.groups.each do |group|
          if @groups.has_key? group
            group = @groups[group]
          else
            group = @groups[group] = []
          end
          group << dependency
        end
      end

      # walk though a final time and add edges
      @env.specs.each do |spec|

        from = @nodes[spec.name]
        spec.runtime_dependencies.each do |dependency|
          from.dependencies << dependency
        end

      end

      @nodes.freeze
      @groups.freeze
      @populated = true
    end

  end

  # Add version info
  class GraphNode

    def initialize(name, version)
      @name = name
      @version = version
      @is_user = false
      @dependencies = []
    end

    attr_reader :name, :dependencies, :version
    attr_accessor :is_user

  end
end
