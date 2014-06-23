class RMX

  def initialize(_object)
    @unsafe_unretained_object_holder = RMXUnsafeUnretainedHolder.new(_object)
    self
  end

  def unsafe_unretained_object
    @unsafe_unretained_object_holder.value
  end

end
