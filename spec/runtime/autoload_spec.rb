require "spec_helper"

describe "Bundler.autoload" do
  before :each do
    build_lib "one", "1.0.0" do |s|
      s.write "lib/baz.rb", "module Baz; end"
      s.write "lib/qux.rb", "module Qux; end"
    end

    build_lib "two", "1.0.0" do |s|
      s.write "lib/two.rb", "module Two; end"
      s.add_dependency "three", "= 1.0.0"
    end

    build_lib "three", "1.0.0" do |s|
      s.write "lib/three.rb", "module Three; end"
      s.add_dependency "seven", "= 1.0.0"
    end

    build_lib "four", "1.0.0" do |s|
      s.write "lib/four.rb", "module Four; end; puts 'four'"
    end

    build_lib "five", "1.0.0", :no_default => true do |s|
      s.write "lib/mofive.rb", "module Five; end"
    end

    build_lib "six", "1.0.0" do |s|
      s.write "lib/six.rb", "module Six; end"
    end

    build_lib "seven", "1.0.0" do |s|
      s.write "lib/seven.rb", "module Seven; end"
    end
    
    build_lib "eight", "1.0.0" do |s|
      s.write "lib/ate.rb", "module Eight; end"
    end

    gemfile <<-G
      path "#{lib_path}"
      gem "one", :group => :bar, :autoload => %w(Baz Qux), :require => %w(baz qux)
      gem "two"
      gem "three", :group => :not
      gem "four", :autoload => false, :require => false
      gem "five"
      gem "six", :group => "string"
      gem "seven", :group => :not
      gem "eight", :require => 'ate', :group => :gate
    G
  end
  
  def run_and_load_all(command)
    run %Q{
      #{command};
      
      loaded = []
      [:Baz, :Qux, :Two, :Three, :Four, :Five, :Six, :Seven, :Eight].each do |sym|
        begin
          loaded << Object.const_get(sym)
        rescue
        end
      end
      
      puts loaded
    }
  end

  it "sets the gems up to autoload in the same manner that require does" do
    # default group
    run_and_load_all "Bundler.autoload"
    check out.should == "Two"

    # specific group
    run_and_load_all "Bundler.autoload(:bar)"
    check out.should == "Baz\nQux"

    # default and specific group
    run_and_load_all "Bundler.autoload(:default, :bar)"
    check out.should == "Baz\nQux\nTwo"

    # specific group given as a string
    run_and_load_all "Bundler.autoload('bar')"
    check out.should == "Baz\nQux"

    # specific group declared as a string
    run_and_load_all "Bundler.autoload(:string)"
    check out.should == "Six"

    # Works even with dependencies that don't require one another
    run_and_load_all "Bundler.autoload(:not)"
    check out.should == "Three\nSeven"
  end
  
  it "allows loading gems with non standard names explicitly" do
    run_and_load_all "Bundler.autoload(:gate)"
    out.should == "Eight"
  end
  
  it "raises an exception if either an explicit or implicit require are missing" do
    gemfile <<-G
      path "#{lib_path}"
      gem "two", :require => 'boom'
      gem "five", :autoload => :Fail
    G

    run <<-R
      Bundler.autoload
      
      begin
        Two
      rescue LoadError => e
        puts e.message
      end
      
      begin
        Five
      rescue NameError => e
        puts e.message
      end
    R
    
    # 1.9.2 is "Object::Five", while 1.8.7 is "Five"
    out.should match /no such file to load -- boom\nuninitialized constant (Object::)?Five/
  end
  
  it "should require gems that are autoload: false, but not require: false" do
    gemfile <<-G
      path "#{lib_path}"
      gem "two",  :autoload => false, :require => false
      gem "four", :autoload => false
    G
    
    run 'Bundler.autoload'
    check out.should == 'four'
  end
  
end
