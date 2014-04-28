module RMExtensions

  module ObjectExtensions

    module Events

      def rmext_events_from_proxy
        @rmext_events_from_proxy ||= EventsFromProxy.new(self)
      end

      def rmext_events_from_proxy?
        !!@rmext_events_from_proxy
      end

      def rmext_events_to_proxy
        @rmext_events_to_proxy ||= EventsToProxy.new(self)
      end

      def rmext_events_to_proxy?
        !!@rmext_events_to_proxy
      end

      # register a callback when an event is triggered on this object.
      def rmext_on(event, opts={}, &block)
        rmext_events_from_proxy.on(event, opts, &block)
      end

      def rmext_now_and_on(event, opts={}, &block)
        rmext_events_from_proxy.now_and_on(event, opts, &block)
      end

      # register a callback when an event is triggered on this object and remove it after it fires once
      def rmext_once(event, opts={}, &block)
        opts[:limit] = 1
        rmext_events_from_proxy.on(event, opts, &block)
      end

      # @model.rmext_off(:fire, self)      # remove :fire in context "self"
      # @model.rmext_off(:fire, &block)    # remove :fire for specific handler
      # @model.rmext_off(:fire)            # remove all :fire in all knowns contexts
      # @model.rmext_off(self)             # remove all events in context "self"
      # @model.rmext_off                   # remove all events in all known contexts
      def rmext_off(event=nil, context=nil, &block)
        if rmext_events_from_proxy?
          rmext_events_from_proxy.off(event, context, &block)
        end
      end

      # remove all event callbacks from other objects in this object's "self"
      def rmext_cleanup(firing_object=nil)
        if rmext_events_to_proxy?
          rmext_events_to_proxy.cleanup(firing_object)
        end
      end

      # trigger an event with value on this object
      def rmext_trigger(event, value=nil)
        if rmext_events_from_proxy?
          rmext_events_from_proxy.trigger(event, value)
        end
      end

      # trigger an event with value on this object
      def rmext_trigger2(event, *values)
        if rmext_events_from_proxy?
          rmext_events_from_proxy.trigger2(event, *values)
        end
      end

    end

  end

  class EventResponse
    attr_accessor :context, :value, :target, :event
  end

  # Proxy object used to hold the firing objects that this real object's
  # "self" owns handlers for.
  # Can be used to cleanup all handlers across all firing objects that have
  # the hanlder's owner (Proc#owner) == this real object.
  # Does not need to perform deallocation logic as nothing is retained
  # and the real object will fall out of the cooresponding EventsFromProxy
  # automatically.
  class EventsToProxy

    rmext_zeroing_weak_attr_accessor :weak_object
    
    def initialize(obj)
      self.weak_object = obj
      @has_handlers_for = NSHashTable.weakObjectsHashTable
    end

    def has_handlers_for!(firing_object)
      if ::RMExtensions.debug?
        p "CONTEXT:", weak_object.rmext_object_desc, "LISTENING TO:", firing_object.rmext_object_desc
      end
      @has_handlers_for.addObject(firing_object)
    end

    def cleanup(firing_object=nil)
      # p "cleanup caller", caller
      if firing_object
        if @has_handlers_for.containsObject(firing_object)
          if ::RMExtensions.debug?
            p "CONTEXT:", weak_object.rmext_object_desc, "UNLISTENING TO:", firing_object.rmext_object_desc
          end
          @has_handlers_for.removeObject(firing_object)
          firing_object.rmext_off(weak_object)
        end
      else
        while firing_object = @has_handlers_for.anyObject
          if ::RMExtensions.debug?
            p "CONTEXT:", weak_object.rmext_object_desc, "UNLISTENING TO:", firing_object.rmext_object_desc
          end
          @has_handlers_for.removeObject(firing_object)
          firing_object.rmext_off(weak_object)
        end
      end
      true
    end

  end

  # Proxy class used to hold the actual handlers and contexts of handlers.
  # When the real class deallocates, all handlers are removed.
  class EventsFromProxy

    rmext_zeroing_weak_attr_accessor :weak_object

    def initialize(obj)
      self.weak_object = obj
      @events = NSMapTable.weakToStrongObjectsMapTable
      if ::RMExtensions.debug?
        p "CREATED #{className}: #{weak_object.rmext_object_desc}"
      end
    end

    def dealloc
      # @did_dealloc = true
      off
      if ::RMExtensions.debug?
        p "DEALLOC #{className}: #{weak_object.rmext_object_desc}"
      end
      super
    end

    def on(event, opts={}, &block)
      return if event.nil? || block.nil?
      event = event.to_s
      context = block.owner
      unless context_events = @events.objectForKey(context)
        context_events = {}
        @events.setObject(context_events, forKey:context)
      end
      unless context_event_blocks = context_events.objectForKey(event)
        context_event_blocks = {}
        context_events.setObject(context_event_blocks, forKey:event)
      end
      block.weak!
      context_event_blocks[block] = opts[:limit] || -1
      # i.e.: controller/view has handlers for object
      context.rmext_events_to_proxy.has_handlers_for!(weak_object)
    end

    def now_and_on(event, opts={}, &block)
      rmext_inline_or_on_main_q do
        res = EventResponse.new
        res.context = block.owner
        res.value = nil
        res.target = weak_object
        res.event = event
        block.call(res)
      end
      on(event, opts, &block)
    end

    def off(event=nil, context=nil, &block)
      if event.is_a?(String) || event.is_a?(Symbol)
        event = event.to_s
        if block
          context = block.owner
          if context_events = @events.objectForKey(context)
            if context_event_blocks = context_events.objectForKey(event)
              if ::RMExtensions.debug?
                p "remove the one block for the event in the blocks #owner", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", context_event_blocks
              end
              context_event_blocks.delete block
            end
          end
        elsif context
          if context_events = @events.objectForKey(context)
            if ::RMExtensions.debug?
              p "remove all handlers for the given event in the given context", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", context_events
            end
            context_events.delete(event)
          end
        else
          keyEnumerator = @events.keyEnumerator
          contexts = []
          while context = keyEnumerator.nextObject
            contexts.push context
          end
          while context = contexts.pop
            if context_events = @events.objectForKey(context)
              if ::RMExtensions.debug?
                p "remove all handlers for the event in all contexts known", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", context_events
              end
              context_events.delete event
            end
          end
        end
      elsif event
        context = event
        if ::RMExtensions.debug?
          p "event is really a context. remove all events and handlers for the context", "CONTEXT:", context.rmext_object_desc, "BLOCKS:", @events.objectForKey(context)
        end
        @events.removeObjectForKey(context)
      else
        if ::RMExtensions.debug?
          p "remove everything"
        end
        @events.removeAllObjects
      end
      nil
    end

    def trigger(event, value)
      rmext_inline_or_on_main_q do
        # next if @did_dealloc
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
              blocks = event_blocks.keys
              if ::RMExtensions.debug?
                p "TRIGGER:", event, "OBJECT:", weak_object.rmext_object_desc, "CONTEXT:", context.rmext_object_desc, "BLOCKS SIZE:", blocks.size
              end
              while block = blocks.pop
                limit = event_blocks[block]
                res = EventResponse.new
                res.context = context
                res.value = value
                res.target = weak_object
                res.event = event
                block.call(res)
                if limit == 1
                  # off
                  if ::RMExtensions.debug?
                    p "LIMIT REACHED:", event, "OBJECT:", weak_object.rmext_object_desc, "CONTEXT:", context.rmext_object_desc
                  end
                  off(event, context, &block)
                elsif limit > 1
                  event_blocks[block] -= 1
                end
              end
            end
          end
        end
      end
      nil
    end

    def trigger2(event, *values)
      rmext_inline_or_on_main_q do
        # next if @did_dealloc
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
              blocks = event_blocks.keys
              if ::RMExtensions.debug?
                p "TRIGGER:", event, "OBJECT:", weak_object.rmext_object_desc, "CONTEXT:", context.rmext_object_desc, "BLOCKS SIZE:", blocks.size
              end
              while block = blocks.pop
                limit = event_blocks[block]
                block.call(*values)
                if limit == 1
                  # off
                  if ::RMExtensions.debug?
                    p "LIMIT REACHED:", event, "OBJECT:", weak_object.rmext_object_desc, "CONTEXT:", context.rmext_object_desc
                  end
                  off(event, context, &block)
                elsif limit > 1
                  event_blocks[block] -= 1
                end
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
