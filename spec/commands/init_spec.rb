# frozen_string_literal: true

RSpec.describe "bundle init" do
  it "generates a Gemfile" do
    bundle :init
    expect(bundled_app("Gemfile")).to exist
  end

  context "when a Gemfile already exists" do
    before do
      gemfile <<-G
        gem "rails"
      G
    end

    it "does not change existing Gemfiles" do
      expect { bundle :init }.not_to change { File.read(bundled_app("Gemfile")) }
    end

    it "notifies the user that an existing Gemfile already exists" do
      bundle :init
      expect(out).to include("Gemfile already exists")
    end
  end

  context "given --gemspec option" do
    let(:spec_file) { tmp.join("test.gemspec") }

    it "should generate from an existing gemspec" do
      File.open(spec_file, "w") do |file|
        file << <<-S
          Gem::Specification.new do |s|
          s.name = 'test'
          s.add_dependency 'rack', '= 1.0.1'
          s.add_development_dependency 'rspec', '1.2'
          end
        S
      end

      bundle :init, :gemspec => spec_file

      gemfile = bundled_app("Gemfile").read
      expect(gemfile).to match(%r{source 'https://rubygems.org'})
      expect(gemfile.scan(/gem "rack", "= 1.0.1"/).size).to eq(1)
      expect(gemfile.scan(/gem "rspec", "= 1.2"/).size).to eq(1)
      expect(gemfile.scan(/group :development/).size).to eq(1)
    end

    context "when gemspec file is invalid" do
      it "notifies the user that specification is invalid" do
        File.open(spec_file, "w") do |file|
          file << <<-S
            Gem::Specification.new do |s|
            s.name = 'test'
            s.invalid_method_name
            end
          S
        end

        bundle :init, :gemspec => spec_file
        expect(out).to include("There was an error while loading `test.gemspec`")
      end
    end
  end

  context "when new_gemfile_name setting is enabled" do
    before { bundle "config new_gemfile_name true" }

    it "generates a gems.rb file" do
      bundle :init
      expect(bundled_app("gems.rb")).to exist
    end

    context "when gems.rb already exists" do
      before do
        create_file("gems.rb", <<-G)
          gem "rails"
        G
      end

      it "does not change existing Gemfiles" do
        expect { bundle :init }.not_to change { File.read(bundled_app("gems.rb")) }
      end

      it "notifies the user that an existing gems.rb already exists" do
        bundle :init
        expect(out).to include("gems.rb already exists")
      end
    end

    context "given --gemspec option" do
      let(:spec_file) { tmp.join("test.gemspec") }

      it "should generate from an existing gemspec" do
        File.open(spec_file, "w") do |file|
          file << <<-S
            Gem::Specification.new do |s|
            s.name = 'test'
            s.add_dependency 'rack', '= 1.0.1'
            s.add_development_dependency 'rspec', '1.2'
            end
          S
        end

        bundle :init, :gemspec => spec_file

        gemfile = bundled_app("gems.rb").read
        expect(gemfile).to match(%r{source 'https://rubygems.org'})
        expect(gemfile.scan(/gem "rack", "= 1.0.1"/).size).to eq(1)
        expect(gemfile.scan(/gem "rspec", "= 1.2"/).size).to eq(1)
        expect(gemfile.scan(/group :development/).size).to eq(1)
      end
    end
  end
end
