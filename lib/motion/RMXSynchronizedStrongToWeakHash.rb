class RMXSynchronizedStrongToWeakHash < RMXStrongToWeakHash

  def initialize
    super
    @queue = Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.rmx.IdentityMap.queue.#{object_id}")
  end

  def [](key)
    res = nil
    @queue.sync do
      res = super
    end
    res
  end

  def []=(key, value)
    res = nil
    @queue.sync do
      res = super
    end
    res
  end

  def delete(key)
    res = nil
    @queue.sync do
      res = super
    end
    res
  end

  def values
    res = nil
    @queue.sync do
      res = super
    end
    res
  end

end
