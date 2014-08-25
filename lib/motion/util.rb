class RMX

  RECURSIVE_LOCK = NSRecursiveLock.new

  def self.mainThread?
    NSThread.currentThread.isMainThread
  end

  def self.synchronized(&block)
    res = nil
    RECURSIVE_LOCK.lock
    res = block.call
    RECURSIVE_LOCK.unlock
    res
  end

  def self.safe_block(block_value=nil, notes=nil, &do_block)
    block = block_value || do_block
    weak_block_owner_holder = RMXWeakHolder.new(block.owner, notes)
    block.weak!
    proc do |*args|
      if wbo = weak_block_owner_holder.value
        block.call(*args)
        true
      else
        if DEBUG_SAFE_BLOCKS
          NSLog("PREVENTED SAFE BLOCK, block owner: #{weak_block_owner_holder.inspect}")
        end
        false
      end
    end
  end

  def self.safe_lambda(block_value=nil, notes=nil, &do_block)
    block = block_value || do_block
    x = safe_block(block, notes)
    case block.arity
    when 0
      -> { x.call }
    when 1
      ->(a) { x.call(a) }
    when 2
      ->(a,b) { x.call(a,b) }
    when 3
      ->(a,b,c) { x.call(a,b,c) }
    when 4
      ->(a,b,c,d) { x.call(a,b,c,d) }
    when 5
      ->(a,b,c,d,e) { x.call(a,b,c,d,e) }
    else
      raise "unsupported arity #{block.arity}"
    end.weak!
  end

  def self.after_animations(&block)
    CATransaction.begin
    sblock = safe_block(block, "after_animations")
    CATransaction.setCompletionBlock(lambda do
      sblock.call
    end.weak!)
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

  def sync_ivar(*args, &block)
    RMX.synchronized do
      ivar(*args, &block)
    end
  end

  def kvo_sync_ivar(*args, &block)
    res = nil
    if object = unsafe_unretained_object
      key = args[0].to_s
      RMX.synchronized do
        object.willChangeValueForKey(key)
        res = ivar(*args, &block)
        object.didChangeValueForKey(key)
      end
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

  def debounce(unique_id, opts={}, &block)
    if (seconds = opts[:seconds]) && seconds > 0
      debounce_seconds(seconds, unique_id, opts[:now], &block)
    else
      debounce_runloop(unique_id, opts[:now], &block)
    end
  end

  def debounce_runloop(unique_id, run_immediately=false, &block)
    if object = unsafe_unretained_object
      lookup = Thread.current["rmx_debounce_runloop"] ||= {}
      key = [ object, unique_id ]
      lookup[key] ||= begin
        block.call if run_immediately
        CFRunLoopPerformBlock(
          CFRunLoopGetCurrent(),
          KCFRunLoopDefaultMode,
          lambda do
            lookup.delete(key)
            block.call
          end
        )
        true
      end
      nil
    end
  end

  def debounce_seconds(seconds, unique_id, run_immediately=false, &block)
    if object = unsafe_unretained_object
      lookup = Thread.current["rmx_debounce_seconds"] ||= {}
      key = [ object, unique_id ]
      lookup[key] ||= begin
        block.call if run_immediately
        units = CFGregorianUnits.new
        units.seconds = seconds
        CFRunLoopAddTimer(
          CFRunLoopGetCurrent(),
          CFRunLoopTimerCreateWithHandler(
            KCFAllocatorDefault,
            CFAbsoluteTimeAddGregorianUnits(
              CFAbsoluteTimeGetCurrent(),
              nil,
              units
            ),
            0,
            0,
            0,
            lambda do |timer|
              lookup.delete(key)
              block.call
            end
          ),
          KCFRunLoopDefaultMode
        )
        true
      end
      nil
    end
  end

end
