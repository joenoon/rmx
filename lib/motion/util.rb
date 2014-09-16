class Proc

  def rmx_weak!(fallback_return=nil, desc=nil)
    block = RMX.safe_block(fallback_return, desc, &self)
    RMX.block_to_lambda_if_possible(arity, &block)
  end

  def rmx_unsafe!
    RMX.block_to_lambda_if_possible(arity, &weak!)
  end

  def rmx_strong!
    RMX.block_to_lambda_if_possible(arity, &self)
  end

end


class RMX

  def self.mainThread?
    NSThread.currentThread.isMainThread
  end

  def self.safe_block(fallback_return=nil, desc=nil, &block)
    weak_block_owner_holder = RMXWeakHolder.new(block.owner)
    block.weak!
    proc do |*args|
      if wbo = weak_block_owner_holder.value
        block.call(*args)
      else
        NSLog("PREVENTED BLOCK (#{[ desc, weak_block_owner_holder.inspect ].compact.join(", ")}).  Something is holding onto this block longer than it should, and probably leaking.")
        fallback_return
      end
    end
  end

  def self.safe_lambda(fallback_return=nil, desc=nil, &block)
    x = safe_block(fallback_return, desc, &block)
    block_to_lambda(block.arity, &x)
  end

  def self.block_to_lambda_if_possible(arity=nil, &block)
    arity ||= block.arity
    if block.lambda?
      block
    elsif arity > -1
      block_to_lambda(arity, &block)
    else
      block
    end
  end

  def self.block_to_lambda(arity=nil, &block)
    arity ||= block.arity
    case arity
    when 0
      -> { block.call }
    when 1
      ->(a) { block.call(a) }
    when 2
      ->(a,b) { block.call(a,b) }
    when 3
      ->(a,b,c) { block.call(a,b,c) }
    when 4
      ->(a,b,c,d) { block.call(a,b,c,d) }
    when 5
      ->(a,b,c,d,e) { block.call(a,b,c,d,e) }
    when 6
      ->(a,b,c,d,e,f) { block.call(a,b,c,d,e,f) }
    when 7
      ->(a,b,c,d,e,f,g) { block.call(a,b,c,d,e,f,g) }
    when 8
      ->(a,b,c,d,e,f,g,h) { block.call(a,b,c,d,e,f,g,h) }
    when 9
      ->(a,b,c,d,e,f,g,h,i) { block.call(a,b,c,d,e,f,g,h,i) }
    when 10
      ->(a,b,c,d,e,f,g,h,i,j) { block.call(a,b,c,d,e,f,g,h,i,j) }
    else
      raise "RMX.block_to_lambda unsupported arity #{block.arity}"
    end.weak!
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

  def self.log_dealloc(object)
    Dispatch::Queue.new("rmx_log_deallocs").sync do
      $rmx_log_deallocs.addObject(object)
    end
    if DEBUG_DEALLOC
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

  # @deprecated
  def debounce(unique_id, opts={}, &block)
    if (seconds = opts[:seconds]) && seconds > 0
      debounce_seconds(seconds, unique_id, opts[:now], &block)
    else
      debounce_runloop(unique_id, opts[:now], &block)
    end
  end

  # @deprecated
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

  # @deprecated
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
