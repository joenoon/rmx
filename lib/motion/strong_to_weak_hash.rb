module RMExtensions

  class StrongToWeakHash < Hash

    def [](key)
      if val = super
        if _val = val.value
          _val.retain
          v = _val
          _val.release
          v
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
      _keys = [] + super
      while _keys.size > 0
        key = _keys.shift
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
