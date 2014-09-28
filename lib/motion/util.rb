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

  def self.after_animations(&block)
    CATransaction.begin
    CATransaction.setCompletionBlock(block.rmx_weak!(nil, "after_animations"))
    CATransaction.commit
  end

  # call the block immediately if called on the main thread,
  # otherwise call it async on the main queue
  #
  # @deprecated
  #
  def self.inline_or_on_main_q(&block)
    if NSThread.currentThread.isMainThread
      block.call
    else
      Dispatch::Queue.main.async do
        block.call
      end
    end
  end

  # call the block immediately if called on the main thread with the given args,
  # otherwise call it async on the main queue.
  # silently ignores nil blocks to avoid if !block.nil? checks, useful for async callbacks
  # that optionally take a callback
  #
  # @deprecated
  #
  def self.block_on_main_q(block, *args)
    unless block.nil?
      inline_or_on_main_q do
        block.call(*args)
      end
    end
  end

  def own_methods
    if object = unsafe_unretained_object
      (object.methods - (object.superclass.methods)).sort
    end
  end

end
