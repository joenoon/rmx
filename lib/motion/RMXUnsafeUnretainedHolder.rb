class RMXUnsafeUnretainedHolder

  def initialize(_value=nil)
    @value_desc = _value.rmx_object_desc
    self.value = _value
    self
  end

  def value
    @holder.nonretainedObjectValue
  end

  def value=(_value)
    @holder = NSValue.valueWithNonretainedObject(_value)
    _value
  end

  def hash
    value.hash
  end

  def eql?(other)
    other.hash == value.hash
  end

  def inspect
    "(unsafe)#{@value_desc}"
  end

end
