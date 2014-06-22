module RMExtensions

  class WeakHolder

    def initialize(_value=nil)
      @value_desc = _value.rmext_object_desc
      @holder = NSHashTable.weakObjectsHashTable
      self.value = _value
      self
    end

    def value
      @holder.anyObject
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
      end
    end

  end

end
