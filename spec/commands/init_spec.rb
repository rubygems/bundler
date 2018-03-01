# frozen_string_literal: true

RSpec.describe "bundle init" do
  it "generates a Gemfile" do
    bundle! :init
    expect(out).to include("Writing new Gemfile")
    expect(bundled_app("Gemfile")).to be_file
  end

  context "when a Gemfile already exists" do
    before do
      create_file "Gemfile", <<-G
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

  context "when a Gemfile exists in a parent directory" do
    let(:subdir) { "child_dir" }

    it "lets users generate a Gemfile in a child directory" do
      bundle! :init

      FileUtils.mkdir bundled_app(subdir)

      Dir.chdir bundled_app(subdir) do
        bundle! :init
      end

      expect(out).to include("Writing new Gemfile")
      expect(bundled_app("#{subdir}/Gemfile")).to be_file
    end
  end

  context "when gemsrb option given" do
    it "generates a gems.rb file" do
      bundle! :init, :gemsrb => true

      expect(bundled_app("gems.rb")).to be_file
    end

    context "when gems.rb already exists" do
      before do
        create_file("gems.rb", <<-G)
          gem "rails"
        G
      end

      it "does not change existing gems.rb" do
        expect { bundle :init, :gemsrb => true }.not_to change { File.read(bundled_app("gems.rb")) }
      end

      it "notifies the user that an existing gems.rb already exists" do
        bundle :init, :gemsrb => true
        expect(out).to include("gems.rb already exists")
      end
    end

    context "when a gems.rb file exists in a parent directory" do
      let(:subdir) { "child_dir" }
      before do
        create_file("gems.rb", <<-G)
          gem "rails"
        G
      end

      it "lets users generate a gems.rb in a child directory" do
        FileUtils.mkdir bundled_app(subdir)

        Dir.chdir bundled_app(subdir) do
          bundle! :init, :gemsrb => true
        end

        expect(out).to include("Writing new gems.rb")
        expect(bundled_app("#{subdir}/gems.rb")).to be_file
      end
    end
  end

  context "when init_gems_rb setting is true" do
    before { bundle! "config init_gems_rb true" }

    it "generates a gems.rb file" do
      bundle :init
      expect(bundled_app("gems.rb")).to be_file
    end

    context "when gems.rb already exists" do
      before do
        create_file("gems.rb", <<-G)
          gem "rails"
        G
      end

      it "does not change existing gems.rb" do
        expect { bundle :init }.not_to change { File.read(bundled_app("gems.rb")) }
      end

      it "notifies the user that an existing gems.rb already exists" do
        bundle :init
        expect(out).to include("gems.rb already exists")
      end
    end

    context "when a gems.rb file exists in a parent directory" do
      let(:subdir) { "child_dir" }
      before do
        create_file("gems.rb", <<-G)
          gem "rails"
        G
      end

      it "lets users generate a gems.rb in a child directory" do
        FileUtils.mkdir bundled_app(subdir)

        Dir.chdir bundled_app(subdir) do
          bundle! :init, :gemsrb => true
        end

        expect(out).to include("Writing new gems.rb")
        expect(bundled_app("#{subdir}/gems.rb")).to be_file
      end
    end
  end

  context "given --gemspec option", :bundler => "< 2" do
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

      gemfile = if Bundler::VERSION[0, 2] == "1."
        bundled_app("Gemfile").read
      else
        bundled_app("gems.rb").read
      end
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
        expect(last_command.bundler_err).to include("There was an error while loading `test.gemspec`")
      end
    end
  end
end
