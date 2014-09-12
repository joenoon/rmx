class RMX

  # requires ReactiveCocoa

  # register a callback when an event is triggered on this object.
  def on(event, opts={}, &block)
    if object = unsafe_unretained_object and sig = rac_signal_for_event(event)
      log("on", event, "opts", opts) if DEBUG_EVENTS

      s = opts[:scheduler]
      if s == :async
        s = RMXRACHelper.schedulerWithHighPriority
      elsif s == :main
        s = RACScheduler.mainThreadScheduler
      end
      s ||= RACScheduler.mainThreadScheduler

      limit = opts[:limit]

      arr = [ object.rmx_object_desc, event ]
      if strong = opts[:strong] 
        arr += [ object, block.owner ]
      end

      sblock = RMX.safe_block(block, "event block: #{arr.inspect}")

      sub = sig.deliverOn(s).subscribeNext(->(args) {

        arr # <- this is to close over object and block.owner if :strong is specified

        log("call", "event", event, "args", args, "arr", arr) if DEBUG_EVENTS

        if limit
          limit -= 1
          if limit == 0
            log("limit reached", event) if DEBUG_EVENTS
            sub.dispose
          end
        end

        unless sblock.call(*args)
          log("killed sub because dead safe block") if DEBUG_EVENTS
          sub.dispose
        end

      })

      if opts[:now]
        sig.sendNext([])
      end

      sub
    end
  end
  
  def log(*args)
    p *args
  end

  def now_and_on(event, opts={}, &block)
    on(event, opts.merge({ :now => true }), &block)
  end

  # register a callback when an event is triggered on this object and remove it after it fires once
  def once(event, opts={}, &block)
    on(event, opts.merge({ :limit => 1 }), &block)
  end

  # RMX(@model).off(:fire)            # remove all :fire events
  # RMX(@model).off                   # remove all events
  def off(event=nil)
    RECURSIVE_LOCK.lock
    if rac_signals = ivar(:rac_signals)
      if event
        if sig = rac_signals[event]
          sig.sendCompleted
          rac_signals.delete(event)
        end
      else
        values = rac_signals.values
        while values.size > 0
          sig = values.shift
          sig.sendCompleted
        end
        rac_signals.clear
      end
    end
    RECURSIVE_LOCK.unlock
  end

  # trigger an event with value on this object
  def trigger(event, *values)
    RECURSIVE_LOCK.lock
    sig = rac_signal_for_event?(event)
    RECURSIVE_LOCK.unlock
    if sig
      log("trigger", event, values, sig) if DEBUG_EVENTS
      sig.sendNext(values)
    end
  end

  def rac_signal_for_event(event)
    rac_signals = ivar(:rac_signals)
    if rac_signals.nil?
      rac_signals = {}
      ivar(:rac_signals, rac_signals)
    end
    rac_signals[event] ||= RACSubject.subject
  end

  def rac_signal_for_event?(event)
    if rac_signals = ivar(:rac_signals)
      rac_signals[event]
    end
  end

end
