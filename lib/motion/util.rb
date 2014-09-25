class RMX

  def self.mainThread?
    NSThread.currentThread.isMainThread
  end

  def self.after_animations(&block)
    CATransaction.begin
    CATransaction.setCompletionBlock(block.rmx_weak!(nil, "after_animations"))
    CATransaction.commit
  end

  # Raises an exception when called from a thread other than the main thread.
  # Good for development and experimenting.
  def self.assert_main_thread!
    raise "Expected main thread. #{Dispatch::Queue.current.description}" unless mainThread?
  end

  # call the block immediately if called on the main thread,
  # otherwise call it async on the main queue
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
  def self.block_on_main_q(block, *args)
    unless block.nil?
      inline_or_on_main_q do
        block.call(*args)
      end
    end
  end

  Dispatch.once do
    $rmx_log_deallocs = NSHashTable.weakObjectsHashTable
  end

  LOG_DEALLOC_QUEUE = Dispatch::Queue.new("rmx_log_deallocs")

  def self.logged_deallocs
    res = nil
    LOG_DEALLOC_QUEUE.sync do
      res = $rmx_log_deallocs.allObjects
    end
    res
  end

  def self.log_dealloc(object, verbose=false)
    LOG_DEALLOC_QUEUE.sync do
      $rmx_log_deallocs.addObject(object)
    end
    if verbose || DEBUG_DEALLOC
      me = object.rmx_object_desc
      NSLog("     -     INIT      - #{me}")
      object.rac_willDeallocSignal.subscribeCompleted(-> {
        NSLog("     -     DEALLOC   - #{me}")
      })
    end
    nil
  end

  def require_queue!(queue, file, line)
    unless Dispatch::Queue.current.description == queue.description
      raise "WRONG QUEUE: was: #{Dispatch::Queue.current.description}, expected: #{queue.description}. #{@unsafe_unretained_object_holder.inspect} #{file}:#{line}, #{caller.inspect}"
    end
  end

  def own_methods
    if object = unsafe_unretained_object
      (object.methods - (object.superclass.methods)).sort
    end
  end

  # Shortcut to instance_variable_get and instance_variable_get:
  # 1 arg for instance_variable_get
  # 1 arg and block for instance_variable_get || instance_variable_set
  # 2 args for instance_variable_set
  def ivar(*args, &block)
    if object = unsafe_unretained_object
      key = args[0]
      val = nil
      if args.size == 1
        if block
          val = object.instance_variable_get("@#{key}")
          if val.nil?
            val = block.call
            object.instance_variable_set("@#{key}", val)
            val
          end
        else
          val = object.instance_variable_get("@#{key}")
        end
      elsif args.size == 2
        val = args[1]
        object.instance_variable_set("@#{key}", val)
      else
        raise "RMX#ivar called with invalid arguments: #{args.inspect}"
      end
      val
    end
  end

  IVAR_LOCK = NSLock.new

  def sync_ivar(*args, &block)
    IVAR_LOCK.lock
    res = ivar(*args, &block)
    IVAR_LOCK.unlock
    res
  end

  def kvo_sync_ivar(*args, &block)
    res = nil
    if object = unsafe_unretained_object
      key = args[0].to_s
      object.willChangeValueForKey(key)
      IVAR_LOCK.lock
      res = ivar(*args, &block)
      IVAR_LOCK.unlock
      object.didChangeValueForKey(key)
    end
    res
  end

  def nil_instance_variables!
    if object = unsafe_unretained_object
      ivars = [] + object.instance_variables
      while ivar = ivars.pop
        object.instance_variable_set(ivar, nil)
      end
      true
    end
  end

end
