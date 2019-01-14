# frozen_string_literal: true

module Bundler
  class Diff
    def initialize(string1, string2)
      @string1 = string1
      @string2 = string2
    end

    def diff
      @diff ||= begin
          @paths = [tempfile(@string1), tempfile(@string2)]

          cmd = format '"%s" %s %s', diff_bin, "-U10000", @paths.map {|s| %("#{s}") }.join(" ")
          diff = `#{cmd}`
          diff.force_encoding("ASCII-8BIT") if diff.respond_to?(:valid_encoding?) && !diff.valid_encoding?
          diff
        end
    ensure
      # unlink the tempfiles explicitly now that the diff is generated
      if defined? @tempfiles # to avoid Ruby warnings about undefined ins var.
        Array(@tempfiles).each do |t|
          begin
            # check that the path is not nil and file still exists.
            # REE seems to be very agressive with when it magically removes
            # tempfiles
            t.unlink if t.path && File.exist?(t.path)
          rescue => e
            warn "#{e.class}: #{e}"
            warn e.backtrace.join("\n")
          end
        end
      end
    end

    def to_s
      diff
      regexp = /^(--- "?#{@paths[0]}"?|\+\+\+ "?#{@paths[1]}"?|@@|\\\\)/
      @diff.split("\n").reject {|x| x =~ regexp }.map {|line| line + "\n" }.join
    end

  private

    def tempfile(string)
      t = Tempfile.new("diffy")
      # ensure tempfiles aren't unlinked when GC runs by maintaining a
      # reference to them.
      @tempfiles ||= []
      @tempfiles.push(t)
      t.print(string)
      t.flush
      t.close
      t.path
    end

    def diff_bin
      return @bin if @bin

      diffs = %w[diff ldiff]
      diffs.first << ".exe" if Bundler::WINDOWS # ldiff does not have exe extension
      @bin = diffs.find {|name| system(name, __FILE__, __FILE__) }

      raise "Can't find a diff executable in PATH #{ENV["PATH"]}" if @bin.nil?
      @bin
    end

    def diff_options
      Array(@options[:context] ? "-U #{@options[:context]}" : @options[:diff])
    end
  end
end
