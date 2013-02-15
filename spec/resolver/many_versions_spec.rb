require "spec_helper"

describe "Resolving with many available versions" do
  it 'resolves in reasonable number of steps' do
    dep 'root'

    # Example of how this blows up the resolver.
    #
    # m   n        calls
    # 1   1             5
    # 2   2            21
    # 3   3           152
    # 4   4          1630
    # 5   5         22668
    # 6   6        382607
    # m   n           ??

    # Not sure what sould make a good unit test really...  Just
    # illustrating that this index triggers a recursive explosion.
    m = n = 5
    @index = a_worst_case_index(m, n)
    @resolver = Bundler::Resolver.new(@index, {}, Bundler::SpecSet.new([]))
    class << @resolver
      # replaced by rspec so we can count calls to #resolve
      def resolve_tic; end
      def resolve(*args)
        resolve_tic
        super(*args)
      end
    end

    @resolver.should_receive(:resolve_tic).at_most(22000).times

    catch(:success) do
      @resolver.start(make_deps)
    end.should be
  end
end
  
