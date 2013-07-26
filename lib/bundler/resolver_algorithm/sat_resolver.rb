module Bundler
  module ResolverAlgorithm
    class SatResolver < Base
      attr_reader :solver
      def start(reqs)
        activated = {}
        @sat_variables = {}
        @gems_size = Hash[reqs.map { |r| [r, gems_size(r)] }]
        @solver = MiniSat::Solver.new
        resolve(reqs, activated)
      end

      def resolve(reqs, activated, depth = 0)
        reqs.each do |current|
          matching_versions = search(current)
          solver << build_cnf_graph(matching_versions)
        end
      end

      private
      def build_cnf_graph(matching_versions)
        matching_versions.each do |dep|
          @sat_variables[dep] = solver.new_var
        end
      end
    end
  end
end
