module RMXCommonMethods

  def rmx_dealloc_inspect
    "#{rmx_object_desc} - dealloc! (queue: #{Dispatch::Queue.current.description})"
  end

  def description
    rmx_object_desc
  end

  def inspect
    rmx_object_desc
  end

end
