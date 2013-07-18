module Bundler
  class CurrentRuby
    def on_18?
      RUBY_VERSION =~ /^1\.8/
    end

    def on_19?
      RUBY_VERSION =~ /^1\.9/
    end

    def on_20?
      RUBY_VERSION =~ /^2\.0/
    end

    def ruby?
      !mswin? && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby" || RUBY_ENGINE == "rbx" || RUBY_ENGINE == "maglev")
    end

    def ruby_18?
      ruby? && on_18?
    end

    def ruby_19?
      ruby? && on_19?
    end

    def ruby_20?
      ruby? && on_20?
    end

    def mri?
      !mswin? && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby")
    end

    def mri_18?
      mri? && on_18?
    end

    def mri_19?
      mri? && on_19?
    end


    def mri_20?
      mri? && on_20?
    end

    def rbx?
      ruby? && defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    end

    def jruby?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    end

    def maglev?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "maglev"
    end

    def mswin?
      Bundler::WINDOWS
    end

    def mingw?
      Bundler::WINDOWS && Gem::Platform.local.os == "mingw32"
    end

    def mingw_18?
      mingw? && on_18?
    end

    def mingw_19?
      mingw? && on_19?
    end

    def mingw_20?
      mingw? && on_20?
    end

  end
end
