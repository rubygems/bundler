module Spec
  module Indexes
    def dep(name, reqs = nil)
      @deps << Bundler::Dependency.new(name, :version => reqs)
    end

    def should_resolve_as(specs)
      got = Bundler::Resolver.resolve(@deps, @index)
      got = got.map { |s| s.full_name }

      got.should == specs.flatten.map { |s| s.full_name }
    end

    def gem(*args, &blk)
      build_spec(*args, &blk)
    end

    def an_awesome_index
      build_index do
        gem "rack", %w(0.8 0.9 0.9.1 0.9.2 1.0 1.1)
        gem "rack-mount", %w(0.4 0.5 0.5.1 0.5.2 0.6)

        # --- Rails
        versions "1.2.3 2.2.3 2.3.5 3.0.0.beta 3.0.0.beta1" do |version|
          gem "activesupport", version
          gem "actionpack", version do
            dep "activesupport", version
            if version >= v('3.0.0.beta')
              dep "rack", '~> 1.1'
              dep "rack-mount", ">= 0.5"
            elsif version > v('2.3.5') then dep "rack", '~> 1.0'
            elsif version > v('2.0.0') then dep "rack", '~> 0.9'
            end
          end
          gem "activerecord", version do
            dep "activesupport", version
            dep "arel", ">= 0.2" if version >= v('3.0.0.beta')
          end
          gem "actionmailer", version do
            dep "activesupport", version
            dep "actionmailer",  version
          end
          if version < v('3.0.0.beta')
            gem "railties", version do
              dep "activerecord",  version
              dep "actionpack",    version
              dep "actionmailer",  version
              dep "activesupport", version
            end
          else
            gem "railties", version
            gem "rails", version do
              dep "activerecord",  version
              dep "actionpack",    version
              dep "actionmailer",  version
              dep "activesupport", version
              dep "railties",      version
            end
          end
        end

        # --- Rails related
        versions '1.2.3 2.2.3 2.3.5' do |version|
          gem "activemerchant", version do
            dep "activesupport", ">= #{version}"
          end
        end
      end
    end
  end
end