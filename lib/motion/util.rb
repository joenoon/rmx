class RMX

  IOS8_COMPAT = UIView.instance_methods.include?(:"setLayoutMargins:")

  def self.mainThread?
    NSThread.currentThread.isMainThread
  end

  # Raises an exception when called from a thread other than the main thread.
  # Good for development and experimenting.
  def self.assert_main_thread!
    raise "Expected main thread. #{Dispatch::Queue.current.description}" unless mainThread?
  end

  def own_methods
    if object = unsafe_unretained_object
      (object.methods - (object.superclass.methods)).sort
    end
  end

end
