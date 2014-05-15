module RMExtensions

  class WeakHolder
    rmext_weak_attr_accessor :value

    def initialize(value)
      self.value = value
    end

    def hash
      value.hash
    end

    def eql?(other)
      other.hash == value.hash
    end

    def inspect
      if val = value
        value.rmext_object_desc
      else
        "(deallocated)"
      end
    end

  end

end
