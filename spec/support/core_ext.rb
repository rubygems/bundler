class Pathname
  def mkdir_p
    FileUtils.mkdir_p(self)
  end

  def touch_p
    dirname.mkdir_p
    touch
  end

  def touch
    FileUtils.touch(self)
  end

  def cp_r(dest)
    FileUtils.cp_r(self, dest)
  end
end