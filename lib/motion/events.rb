class RMX

  # requires ReactiveCocoa

  # register a callback when an event is triggered on this object.
  def on(event, opts={}, &block)
    if object = unsafe_unretained_object and sig = rac_signal_for_event(event)
      log("on", event, "opts", opts) if DEBUG_EVENTS

      q = opts[:queue]
      if q == :async
        q = RMXEventsFromProxy::QUEUE
      elsif q == :main
        q = Dispatch::Queue.main
      end
      q ||= Dispatch::Queue.main

      limit = opts[:limit]

      arr = [ object.rmx_object_desc, event ]
      if strong = opts[:strong] 
        arr += [ object, block.owner ]
      end

      sblock = RMX.safe_block(block)

      sub = sig.subscribeNext(->(args) {

        arr # <- this is to close over object and block.owner if :strong is specified

        log("call", "event", event, "args", args, "arr", arr) if DEBUG_EVENTS

        if limit
          limit -= 1
          if limit == 0
            log("limit reached", event) if DEBUG_EVENTS
            sub.dispose
          end
        end

        if q == Dispatch::Queue.main
          RMX.block_on_main_q(sblock, *args)
        else
          q.async do
            sblock.call(*args)
          end
        end

      })

      if opts[:now]
        sig.sendNext([])
      end

      RMX.safe_block(proc do
        log("off_block called", event) if DEBUG_EVENTS
        sub.dispose
      end)
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
    RMX.synchronized do
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
    end
  end

  # trigger an event with value on this object
  def _trigger(event, *values)
    RMX.synchronized do
      if sig = rac_signal_for_event?(event)
        log("trigger", event, values, sig) if DEBUG_EVENTS
        sig.sendNext(values)
      end
    end
  end

  if RMX::Env['rmx_trigger_async'] == '1'

    def trigger(event, *values)
      RMXEventsFromProxy::QUEUE.async do
        _trigger(event, *values)
      end
    end

  else

    alias_method 'trigger', '_trigger'

  end

  def rac_signal_for_event(event)
    RMX.synchronized do
      rac_signals = ivar(:rac_signals)
      if rac_signals.nil?
        rac_signals = {}
        ivar(:rac_signals, rac_signals)
      end
      rac_signals[event] ||= RACSubject.subject
    end
  end

  def rac_signal_for_event?(event)
    RMX.synchronized do
      if rac_signals = ivar(:rac_signals)
        rac_signals[event]
      end
    end
  end

end
