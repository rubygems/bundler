# frozen_string_literal: true
module Bundler
  module VersionRanges
    NEq = Struct.new(:version)
    ReqR = Struct.new(:left, :right)
    class ReqR
      Endpoint = Struct.new(:version, :inclusive)
      def to_s
        "#{left.inclusive ? "[" : "("}#{left.version}, #{right.version}#{right.inclusive ? "]" : ")"}"
      end
      INFINITY = Object.new.freeze
      ZERO = Gem::Version.new("0.a")

      def cover?(v)
        return false if left.inclusive && left.version > v
        return false if !left.inclusive && left.version >= v

        if right.version != INFINITY
          return false if right.inclusive && right.version < v
          return false if !right.inclusive && right.version <= v
        end

        true
      end

      def empty?
        left.version == right.version && !(left.inclusive && right.inclusive)
      end
    end

    def self.for_many(requirements)
      requirement = requirements.reduce(Gem::Requirement.new(">= 0.a")) do |acc, elem|
        acc.concat(elem.requirements.map {|r| r.join(" ") })
        acc
      end
      self.for(requirement)
    end

    def self.for(requirement)
      ranges = requirement.requirements.map do |op, v|
        case op
        when "=" then ReqR.new(ReqR::Endpoint.new(v, true), ReqR::Endpoint.new(v, true))
        when "!=" then NEq.new(v)
        when ">=" then ReqR.new(ReqR::Endpoint.new(v, true), ReqR::Endpoint.new(ReqR::INFINITY, false))
        when ">" then ReqR.new(ReqR::Endpoint.new(v, false), ReqR::Endpoint.new(ReqR::INFINITY, false))
        when "<" then ReqR.new(ReqR::Endpoint.new(ReqR::ZERO, true), ReqR::Endpoint.new(v, false))
        when "<=" then ReqR.new(ReqR::Endpoint.new(ReqR::ZERO, true), ReqR::Endpoint.new(v, true))
        when "~>" then ReqR.new(ReqR::Endpoint.new(v, true), ReqR::Endpoint.new(v.bump, false))
        end
      end.uniq
      ranges, neqs = ranges.partition {|r| !r.is_a?(NEq) }
      ranges << ReqR.new(ReqR::Endpoint.new(Gem::Version.new("0.a"), true), ReqR::Endpoint.new(ReqR::INFINITY, false)) if ranges.empty?

      [ranges.sort_by {|range| [range.left.version, range.left.inclusive ? 0 : 1] }, neqs]
    end

    def self.empty?(ranges, neqs)
      !ranges.reduce do |last_range, curr_range|
        next false unless last_range
        next curr_range if last_range.right.version == ReqR::INFINITY
        case last_range.right.version <=> curr_range.left.version
        when 1 then next curr_range
        when 0 then next(last_range.right.inclusive && curr_range.left.inclusive && !neqs.include?(curr_range.left.version) && curr_range)
        when -1 then next false
        end
      end
    end
  end
end
