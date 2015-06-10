class RMX

  IOS8_COMPAT = UIView.instance_methods.include?(:"setLayoutMargins:")

  # Raises an exception when called from a thread other than the main thread.
  # Good for development and experimenting.
  def self.assert_main_thread!(str="")
    raise "Expected main thread. #{Dispatch::Queue.current.description} #{str}" unless RACScheduler.isOnMainThread
  end

  def own_methods
    if object = unsafe_unretained_object
      (object.methods - (object.superclass.methods)).sort
    end
  end

  def self.boolValue(val)
    if val.is_a?(Numeric)
      val.boolValue
    else
      !!val
    end
  end

  def self.logMethodCall(obj, signature)
    obj_desc = obj.rmx_object_desc
    obj.rac_signalForSelector(signature)
    .subscribeNext(->(tuple) {
      NSLog("[RMX.logMethodCall](#{obj_desc}##{signature}) args: #{tuple.allObjects}")
    })
    nil
  end

end
