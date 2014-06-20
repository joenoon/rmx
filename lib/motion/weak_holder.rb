module RMExtensions

  class WeakHolder
    rmext_weak_attr_accessor :value

    def initialize(_value)
      @value_desc = _value.rmext_object_desc
      self.value = _value
      self
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
