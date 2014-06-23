class RMXWeakToStrongHash < Hash

  def [](key)
    super(RMXWeakHolder.new(key))
  end

  def []=(key, value)
    super(RMXWeakHolder.new(key), value)
  end

  def delete(key)
    super(RMXWeakHolder.new(key))
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
