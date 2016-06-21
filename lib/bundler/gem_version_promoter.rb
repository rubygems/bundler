# frozen_string_literal: true
module Bundler
  class GemVersionPromoter
    attr_reader :level, :locked_specs, :unlock_gems
    attr_accessor :strict

    def initialize(locked_specs = SpecSet.new([]), unlock_gems = [])
      @level_default = :major
      @level = @level_default
      @strict = false
      @locked_specs = locked_specs
      @unlock_gems = unlock_gems
      @sort_versions = {}
    end

    def level=(value)
      v = begin
        case value
        when String, Symbol
          value.to_sym
        end
      end

      @level = [:major, :minor, :patch].include?(v) ? v : @level_default
    end

    def sort_versions(dep, dep_specs)
      # MODO Revisit env name - also see below
      before_result = "before sort_versions: #{debug_format_result(dep, dep_specs).inspect}" if ENV["DEBUG_PATCH_RESOLVER"]

      result = @sort_versions[dep] ||= begin
        gem_name = dep.name

        # An Array per version returned, different entries for different platforms.
        # We only need the version here so it's ok to hard code this to the first instance.
        locked_spec = @locked_specs[gem_name].first

        if @strict
          filter_dep_specs(dep_specs, locked_spec)
        else
          sort_dep_specs(dep_specs, locked_spec)
        end.tap do |specs|
          if ENV["DEBUG_PATCH_RESOLVER"] # MODO: proper debug flag name, check and proper debug output
            STDERR.puts before_result
            STDERR.puts " after sort_versions: #{debug_format_result(dep, specs).inspect}"
          end
        end
      end
      # MODO: flush out this problem by freezing it?
      result.dup # not ideal, but elsewhere in bundler the resulting array is occasionally emptied, corrupting the cache.
    end

  private

    def filter_dep_specs(specs, locked_spec)
      res = specs.select do |sg|
        # SpecGroup is grouped by name/version, multiple entries for multiple platforms.
        # We only need the name, which will be the same, so hard coding to first is ok.
        gem_spec = sg.first

        if locked_spec
          gsv = gem_spec.version
          lsv = locked_spec.version

          must_match = @level == :minor ? [0] : [0, 1]

          matches = must_match.map {|idx| gsv.segments[idx] == lsv.segments[idx] }
          (matches.uniq == [true]) ? (gsv >= lsv) : false
        else
          true
        end
      end

      sort_dep_specs(res, locked_spec)
    end

    # reminder: sort still filters anything older than locked version
    # :major bundle update behavior can move a gem to an older version
    # in order to satisfy the dependency tree.
    def sort_dep_specs(specs, locked_spec)
      return specs unless locked_spec
      gem_name = locked_spec.name
      locked_version = locked_spec.version

      filtered = specs.select {|s| s.first.version >= locked_version }

      filtered.sort do |a, b|
        a_ver = a.first.version
        b_ver = b.first.version
        case
        when a_ver.segments[0] != b_ver.segments[0]
          b_ver <=> a_ver
        when !(@level == :minor) && (a_ver.segments[1] != b_ver.segments[1])
          b_ver <=> a_ver
        else
          a_ver <=> b_ver
        end
      end.tap do |result|
        unless unlocking_gem?(gem_name)
          move_version_to_end(specs, locked_version, result)
        end
      end
    end

    def unlocking_gem?(gem_name)
      @unlock_gems.empty? || @unlock_gems.include?(gem_name)
    end

    def move_version_to_end(specs, version, result)
      spec_group = specs.detect {|s| s.first.version.to_s == version.to_s }
      return unless spec_group
      result.reject! {|s| s.first.version.to_s == version.to_s }
      result << spec_group
    end

    def debug_format_result(dep, res)
      a = [dep.to_s,
           res.map {|sg| [sg.version, sg.dependencies_for_activated_platforms.map {|dp| [dp.name, dp.requirement.to_s] }] }]
      [a.first, a.last.map {|sg_data| [sg_data.first.version, sg_data.last.map {|aa| aa.join(" ") }] },
       @level, @strict ? :strict : :not_strict]
    end
  end
end
