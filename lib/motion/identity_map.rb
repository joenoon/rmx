module RMExtensions

  class IdentityMap < StrongToWeakHash

    def initialize
      super
      @queue = Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.rmx.IdentityMap.queue.#{object_id}")
    end

    def [](key)
      @queue.sync do
        return super
      end
    end

    def []=(key, value)
      @queue.sync do
        return super
      end
    end

    def delete(key)
      @queue.sync do
        return super
      end
    end

    def values
      @queue.sync do
        return super
      end
    end

  end

end
