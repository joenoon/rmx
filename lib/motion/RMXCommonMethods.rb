module RMXCommonMethods

  def rmx_dealloc
  end

  if RMX::DEBUG_DEALLOC
    def dealloc
      p " - dealloc! (queue: #{Dispatch::Queue.current.description})"
      rmx_dealloc
      super
    end
  else
    def dealloc
      rmx_dealloc
      super
    end
  end

  def description
    rmx_object_desc
  end

  def inspect
    rmx_object_desc
  end

end
