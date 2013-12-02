module RMExtensions

  module ObjectExtensions

    module Observation

      def rmext_observation_proxy
        @rmext_observation_proxy ||= ObservationProxy.new(self)
      end

      def rmext_observe_passive(object, keyPath:key, withBlock:block)
        rmext_observe(object, keyPath:key, options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld), withBlock:block)
      end

      def rmext_observe(object, keyPath:key, withBlock:block)
        rmext_observe(object, keyPath:key, options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial), withBlock:block)
      end

      def rmext_observe(object, keyPath:key, options:options, withBlock:block)
        rmext_observation_proxy.observe(object, keyPath:key, options:options, withBlock:block)
      end

      # unobserve an existing observation
      def rmext_unobserve(object, keyPath:key)
        if @rmext_observation_proxy
          @rmext_observation_proxy.unobserve(object, keyPath:key)
        end
      end

      # unobserve all existing observations
      def rmext_unobserve_all
        if @rmext_observation_proxy
          @rmext_observation_proxy.unobserve_all
        end
      end

      # register a callback when an event is trigger on this object
      def rmext_on(event, inContext:context, withBlock:block)
        rmext_observation_proxy.on(event, inContext:context, withBlock:block)
      end

      # remove a specific callback for an event on this object
      def rmext_off(event, inContext:context, withBlock:block)
        if @rmext_observation_proxy
          @rmext_observation_proxy.off(event, inContext:context, withBlock:block)
        end
      end

      # remove all event callbacks on this object
      def rmext_off_all
        if @rmext_observation_proxy
          @rmext_observation_proxy.off_all
        end
      end

      # trigger an event with value on this object
      def rmext_trigger(event, value=nil)
        if @rmext_observation_proxy
          @rmext_observation_proxy.trigger(event, value)
        end
      end

      # remove all observations and event callbacks on this object
      def rmext_cleanup
        if @rmext_observation_proxy
          @rmext_observation_proxy.cleanup
        end
      end

    end

  end

  class ObservationResponse
    attr_accessor :context, :value, :old_value, :target, :key, :indexes, :kind
  end

  class EventResponse
    attr_accessor :context, :value, :target, :event
  end

  # # Proxy class used to hold the actual observation and watches for the real
  # # class intended to hold the observation to be deallocated, so the
  # # observation can be cleaned up.
  class ObservationProxy

    def initialize(obj)
      @weak_object = WeakRef.new(obj)
      @desc = obj.inspect
      @events = NSMapTable.weakToStrongObjectsMapTable
      @targets = {}
      if ::RMExtensions.debug?
        p "created ObservationProxy(#{@desc})"
      end
    end

    def dealloc
      @did_dealloc = true
      cleanup
      if ::RMExtensions.debug?
        p "dealloc ObservationProxy(#{@desc})"
      end
      super
    end

    def cleanup
      if ::RMExtensions.debug?
        p "cleanup ObservationProxy(#{@desc})"
      end
      unobserve_all
      off_all
      true
    end

    def observe(target, keyPath:key_path, options:options, withBlock:block)
      already_registered = registered?(target, key_path)
      add_observer_block(target, key_path, block)
      target.addObserver(self, forKeyPath:key_path, options:options, context:nil) unless already_registered
    end

    def unobserve(target, keyPath:key_path)
      return unless registered?(target, key_path)
      target.removeObserver(self, forKeyPath:key_path)
      remove_observer_block(target, key_path)
    end

    def remove_observer_block(target, key_path)
      return if target.nil? || key_path.nil?
      key_path = key_path.to_s
      target_hash = @targets[target]
      if !target_hash.nil? && target_hash.has_key?(key_path)
        target_hash.delete(key_path)
      end
    end

    def unobserve_all
      keys = [] + @targets.keys
      while target = keys.pop
        target_hash = @targets[target]
        paths = [] + target_hash.keys
        while key_path = paths.pop
          unobserve(target, keyPath:key_path)
        end
      end
      @targets.removeAllObjects
    end

    def registered?(target, key_path)
      !target.nil? && !@targets[target].nil? && @targets[target].has_key?(key_path.to_s)
    end

    def add_observer_block(target, key_path, block)
      return if target.nil? || key_path.nil? || block.nil?
      key_path = key_path.to_s
      @targets[target] ||= {}
      @targets[target][key_path] ||= []
      @targets[target][key_path].addObject block
    end

    # NSKeyValueObserving Protocol

    def observeValueForKeyPath(key_path, ofObject:target, change:change, context:context)
      m_desc = nil
      if ::RMExtensions.debug?
        m_desc = "~~> ObservationProxy(#{@desc})#observeValueForKeyPath(#{key_path}, ofObject:#{target.inspect.split(" ").first}>, ...)"
        p "called", m_desc
      end
      action = proc do
        next if @did_dealloc
        next if target.nil?
        key_paths = @targets[target]
        next if key_paths.nil?
        blocks = key_paths[key_path]
        next if blocks.nil?
        blocks = [] + blocks # get a new array that can be popped
        if ::RMExtensions.debug?
          p "blocks.size", blocks.size, m_desc
        end
        while blk = blocks.pop
          res = ObservationResponse.new
          res.context = @weak_object
          res.value = change[NSKeyValueChangeNewKey]
          res.old_value = change[NSKeyValueChangeOldKey]
          res.target = target
          res.key = key_path
          res.indexes = change[NSKeyValueChangeIndexesKey]
          res.kind = change[NSKeyValueChangeKindKey]
          blk.call(res)
        end
      end
      if NSThread.currentThread.isMainThread
        if ::RMExtensions.debug?
          p "inline execution", m_desc
        end
        action.call
      else
        if ::RMExtensions.debug?
          p "dispatch execution", m_desc
        end
        rmext_on_main_q(&action)
      end
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
      context_event_blocks.addObject block
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

    def off_all
      @events.removeAllObjects
    end

    def trigger(event, value)
      m_desc = nil
      if ::RMExtensions.debug?
        m_desc = "~~> ObservationProxy(#{@desc})#trigger(#{event}, #{value.inspect.split(" ").first }>)"
        p "called", m_desc
      end
      rmext_on_main_q do
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
              if ::RMExtensions.debug?
                p "blocks.size", blocks.size, m_desc
              end
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
Object.send(:include, ::RMExtensions::ObjectExtensions::Observation)
