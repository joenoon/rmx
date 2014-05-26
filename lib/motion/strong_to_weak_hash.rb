module RMExtensions

  class StrongToWeakHash < Hash

    def [](key)
      if val = super
        if val = val.value
          val.retain.autorelease
        end
      end
    end

    def []=(key, value)
      super(key, value.nil? ? nil : WeakHolder.new(value))
      value
    end

    def delete(key)
      if val = super
        val.value
      end
    end

    def keys
      out = []
      keys = [] + super
      while keys.size > 0
        key = keys.shift
        if val = self[key]
          out << key
        end
      end
      out
    end

    def values
      out = []
      values = [] + super
      while values.size > 0
        value = values.shift
        if val = value.value
          out << val
        end
      end
      out
    end

  end

end
