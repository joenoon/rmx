class RMXWeakHolder

  def initialize(_value=nil, _notes=nil)
    @value_desc = _value.rmx_object_desc
    @notes = _notes
    @holder = NSHashTable.weakObjectsHashTable
    self.value = _value
    self
  end

  def value(&block)
    v = @holder.anyObject
    if v && !block.nil?
      block.call(v)
    end
    v
  end

  def value=(_value)
    @holder.removeAllObjects
    @holder.addObject(_value) unless _value.nil?
    _value
  end

  def hash
    value.hash
  end

  def eql?(other)
    other.hash == value.hash
  end

  def inspect
    if val = value
      "(weak)#{@value_desc}"
    else
      "(deallocated)#{@value_desc}"
    end + (@notes ? "(#{@notes})" : "")
  end

end
