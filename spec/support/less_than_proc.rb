class LessThanProc < Proc
  attr_accessor :present

  def self.with(present)
    pv = Gem::Version.new(present.dup)
    lt = self.new { |required| pv < Gem::Version.new(required) }
    lt.present = present
    return lt
  end

  def inspect
    "\"=< #{present.to_s}\""
  end
end
