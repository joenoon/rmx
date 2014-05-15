module RMExtensions

  class WeakToStrongHash < Hash

    def [](key)
      super(WeakHolder.new(key))
    end

    def []=(key, value)
      super(WeakHolder.new(key), value)
    end

    def delete(key)
      super(WeakHolder.new(key))
    end

    def keys
      out = []
      keys = [] + super
      while keys.size > 0
        key = keys.shift
        if val = key.value
          out << val
        end
      end
      out
    end

    def values
      out = []
      keys = [] + self.keys
      while keys.size > 0
        key = keys.shift
        if val = key.value
          out << self[key]
        end
      end
      out
    end

  end

end
