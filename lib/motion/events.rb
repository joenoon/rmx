class RMX

  CREATE_EVENT_PROXY = proc do
    RMXEventsFromProxy.new
  end

  def events_from_proxy
    sync_ivar(:_rmx_events_from_proxy, &CREATE_EVENT_PROXY)
  end

  def _events_from_proxy
    sync_ivar(:_rmx_events_from_proxy)
  end

  # register a callback when an event is triggered on this object.
  def on(event, opts={}, &block)
    if object = unsafe_unretained_object
      _opts = opts.dup
      if _opts[:strong]
        _opts[:strong] = [ object, block.owner ]
      end
      events_from_proxy.on(event, _opts, &block)
    end
  end

  def now_and_on(event, opts={}, &block)
    events_from_proxy.now_and_on(event, opts.dup, &block)
  end

  # register a callback when an event is triggered on this object and remove it after it fires once
  def once(event, opts={}, &block)
    _opts = opts.dup
    _opts[:limit] = 1
    on(event, _opts, &block)
  end

  # RMX(@model).off(:fire, &block)    # remove :fire for specific handler
  # RMX(@model).off(:fire)            # remove all :fire in all knowns contexts
  # RMX(@model).off                   # remove all events in all known contexts
  def off(event=nil, execution_block=nil)
    if proxy = _events_from_proxy
      proxy.off(event, execution_block)
    end
  end

  # trigger an event with value on this object
  def trigger(event, *values)
    if proxy = _events_from_proxy
      proxy.trigger(event, *values)
    end
  end

end
