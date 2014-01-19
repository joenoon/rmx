module RMExtensions

  module ObjectExtensions

    module Events

      def rmext_events_proxy
        @rmext_events_proxy ||= EventsProxy.new(self)
      end

      # register a callback when an event is triggered on this object.
      def rmext_on(object, event, &block)
        object.rmext_events_proxy.on(event, inContext:self, withBlock:block)
      end

      def rmext_now_and_on(object, event, &block)
        object.rmext_events_proxy.now_and_on(event, inContext:self, withBlock:block)
      end

      # register a callback when an event is triggered on this object and remove it after it fires once
      def rmext_once(object, event, &block)
        object.rmext_events_proxy.once(event, inContext:self, withBlock:block)
      end

      # remove a specific callback for an event on object
      def rmext_off(object, event, &block)
        if object.rmext_events_proxy?
          object.rmext_events_proxy.off(event, inContext:self, withBlock:block)
        end
      end

      # remove all event callbacks on this object,
      # remove all event callbacks from other objects in this object's "self"
      def rmext_cleanup
        if @rmext_events_proxy
          @rmext_events_proxy.cleanup
        end
      end

      ### these get called on the object: ie. @model.rmext_off_all

      # remove all event callbacks on this object
      def rmext_off_all
        if @rmext_events_proxy
          @rmext_events_proxy.off_all
        end
      end

      # trigger an event with value on this object
      def rmext_trigger(event, value=nil)
        if @rmext_events_proxy
          @rmext_events_proxy.trigger(event, value)
        end
      end

    end

  end

  class EventResponse
    attr_accessor :context, :value, :target, :event
  end

  # Proxy class used to hold the actual listeners and contexts where listening
  # and watches for the real class intended to hold the observation to be
  # deallocated, so the events can be cleaned up.
  class EventsProxy

    def initialize(obj)
      @weak_object = WeakRef.new(obj)
      @desc = obj.inspect
      @events = NSMapTable.weakToStrongObjectsMapTable
      @listenings = NSHashTable.weakObjectsHashTable
      if ::RMExtensions.debug?
        p "created EventsProxy(#{@desc})"
      end
    end

    def dealloc
      @did_dealloc = true
      cleanup
      if ::RMExtensions.debug?
        p "dealloc EventsProxy(#{@desc})"
      end
      super
    end

    def cleanup
      off_all
      off_all_context
      true
    end

    def on(event, inContext:context, withBlock:block)
      return if event.nil? || block.nil?
      event = event.to_s
      context ||= self.class
      unless context_events = @events.objectForKey(context)
        context_events = {}
        @events.setObject(context_events, forKey:context)
      end
      unless context_event_blocks = context_events.objectForKey(event)
        context_event_blocks = []
        context_events.setObject(context_event_blocks, forKey:event)
      end
      block.weak!
      context_event_blocks.addObject block
      # i.e.: controller/view listening_to model
      context.rmext_events_proxy.listening_to(@weak_object)
    end

    def listening_to(object)
      if ::RMExtensions.debug?
        p "listening_to object", object.class, "from context", @weak_object.class
      end
      @listenings.addObject(object)
    end

    def now_and_on(event, inContext:context, withBlock:block)
      rmext_inline_or_on_main_q do
        res = EventResponse.new
        res.context = context
        res.value = nil
        res.target = @weak_object
        res.event = event
        block.call(res)
      end
      on(event, inContext:context, withBlock:block)
    end

    def off(event, inContext:context, withBlock:block)
      return if event.nil? || block.nil?
      event = event.to_s
      context ||= self.class
      return unless context_events = @events.objectForKey(context)
      return unless context_event_blocks = context_events.objectForKey(event)
      context_event_blocks.removeObject block
      nil
    end

    def once(event, inContext:context, withBlock:block)
      block.weak!
      once_block = lambda do |opts|
        off(event, inContext:context, withBlock:once_block)
        block.call(opts)
      end
      on(event, inContext:context, withBlock:once_block)
    end

    def off_all
      @events.removeAllObjects
    end

    def off_context(context)
      @events.setObject(nil, forKey:context)
    end

    def off_all_context
      while object = @listenings.anyObject
        if ::RMExtensions.debug?
          p "remove object", object.class, "from context", @weak_object.class
        end
        @listenings.removeObject(object)
        object.rmext_events_proxy.off_context(@weak_object)
      end
    end

    def trigger(event, value)
      # m_desc = nil
      # if ::RMExtensions.debug?
      #   m_desc = "~~> EventsProxy(#{@desc})#trigger(#{event}, #{value.inspect.split(" ").first }>)"
      #   p "called", m_desc
      # end
      rmext_inline_or_on_main_q do
        next if @did_dealloc
        next if event.nil?
        event = event.to_s
        keyEnumerator = @events.keyEnumerator
        contexts = []
        while context = keyEnumerator.nextObject
          contexts.push context
        end
        while context = contexts.pop
          if context_events = @events.objectForKey(context)
            if event_blocks = context_events[event]
              blocks = [] + event_blocks
              # if ::RMExtensions.debug?
              #   p "blocks.size", blocks.size, m_desc
              # end
              while blk = blocks.pop
                res = EventResponse.new
                res.context = context
                res.value = value
                res.target = @weak_object
                res.event = event
                blk.call(res)
              end
            end
          end
        end
      end
      nil
    end
  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Events)
