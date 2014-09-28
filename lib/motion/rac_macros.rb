class RMX

  # Our version of the RACObserve macro:
  #
  # Simple version:
  #
  #   RMX(target).racObserve(keypath)
  #   i.e. RMX(self).racObserve("items")
  #
  # Separate observer and target version (when you want to observe a keypath
  # on an object other than self):
  #
  #   RMX(observer).racObserve(target, keypath)
  #   i.e. RMX(self).racObserve(other_object, "items")
  #
  # Which to use depends on what needs to be considered for deallocation.
  # For more information, check rac's `rac_valuesForKeyPath`.
  #
  def racObserve(*args)
    if object = unsafe_unretained_object
      keypath = args.pop
      target = args.pop || object
      observer = target == object ? nil : object
      target.rac_valuesForKeyPath(keypath, observer:observer)
    end
  end

  # Our version of the RAC macro:
  #
  # Simple version:
  #
  #   RMX(target).rac(keypath).signal = a_signal
  #   i.e. RMX(self).rac("items").signal = a_signal
  #
  # Like the RAC macro, a default nilValue can be given. If the
  # assigned signal `nexts` a nil, this nilValue will be used instead.
  #
  #   RMX(target).rac(keypath, 42).signal = a_signal_that_nexts_nil
  #   i.e. RMX(self).rac("items", 42).signal = a_signal_that_nexts_nil
  #
  # For more information, check rac's RACSubscriptingAssignmentTrampoline.h.
  #
  def rac(keypath, nilval=nil)
    if object = unsafe_unretained_object
      RMXRACAssignmentHelper.new(RACSubscriptingAssignmentTrampoline.alloc.initWithTarget(object, nilValue:nilval), keypath)
    end
  end

end
