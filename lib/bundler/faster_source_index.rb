class FasterSourceIndex
  def initialize(index)
    @index = index
    @new_index = Hash.new {|h,k| h[k] = {}}
    @index.gems.values.each do |spec|
      @new_index[spec.name][spec.version] = spec
    end
    @results = {}
  end

  def search(dependency)
    @results[dependency.hash] ||= begin
      possibilities = @new_index[dependency.name].values
      possibilities.select do |spec|
        dependency =~ spec
      end.sort_by {|s| s.version }
    end
  end
end