module RMExtensions

  EVENTS_QUEUE = Dispatch::Queue.new("RMX.EventsFromProxy")

  module ObjectExtensions

    module Events

      CREATE_EVENT_PROXY = proc do
        EventsFromProxy.new
      end

      def rmext_events_from_proxy
        res = nil
        EVENTS_QUEUE.sync do
          res = rmext_ivar(:rmext_events_from_proxy, &CREATE_EVENT_PROXY)
        end
        res
      end

      def rmext_events_from_proxy?
        res = nil
        EVENTS_QUEUE.sync do
          res = !!@rmext_events_from_proxy
        end
        res
      end

      # register a callback when an event is triggered on this object.
      def rmext_on(event, opts={}, &block)
        _opts = opts.dup
        if _opts[:strong]
          _opts[:strong] = [ self, block.owner ]
        end
        rmext_events_from_proxy.on(event, _opts, &block)
      end

      def rmext_now_and_on(event, opts={}, &block)
        rmext_events_from_proxy.now_and_on(event, opts.dup, &block)
      end

      # register a callback when an event is triggered on this object and remove it after it fires once
      def rmext_once(event, opts={}, &block)
        _opts = opts.dup
        _opts[:limit] = 1
        rmext_on(event, _opts, &block)
      end

      # @model.rmext_off(:fire, self)      # remove :fire in context "self"
      # @model.rmext_off(:fire, &block)    # remove :fire for specific handler
      # @model.rmext_off(:fire)            # remove all :fire in all knowns contexts
      # @model.rmext_off(self)             # remove all events in context "self"
      # @model.rmext_off                   # remove all events in all known contexts
      def rmext_off(event=nil, execution_block=nil)
        if rmext_events_from_proxy?
          rmext_events_from_proxy.off(event, execution_block)
        end
      end

      # trigger an event with value on this object
      def rmext_trigger(event, *values)
        if rmext_events_from_proxy?
          rmext_events_from_proxy.trigger(event, *values)
        end
      end

    end

  end

  class ExecutionBlock
    attr_accessor :queue, :the_block, :dead, :desc, :strong, :meta, :limit
    rmext_weak_attr_accessor :block_owner

    def block=(_block)
      self.block_owner = _block.owner
      self.the_block = RMExtensions.safe_block(_block)
    end

    def actual_queue
      q = queue
      if q == :async
        q = EVENTS_QUEUE
      elsif q == :main
        q = Dispatch::Queue.main
      end
      q ||= Dispatch::Queue.main
      q
    end

    def call(*args)
      should_cleanup = false
      if !dead && (blk = the_block) && (o = block_owner) && (q = actual_queue)
        q.async do
          blk.call(*args)
          blk
          o
        end
      else
        should_cleanup = true
      end
      if limit
        if limit > 0
          self.limit -= 1
        end
        if limit == 0
          should_cleanup = true
        end
      end
      if should_cleanup
        self.dead = true
        self.strong = nil
        self.meta = nil
        self.limit = nil
        self.the_block = nil
        self.block_owner = nil
      end
    end

  end

  # Proxy class used to hold the actual handlers and contexts of handlers.
  # When the real class deallocates, all handlers are removed.
  class EventsFromProxy

    def initialize
      @events = {}
    end

    # def rmext_dealloc
    #   off
    #   super
    # end

    def on(event, opts={}, &block)
      block ||= proc {}
      event = event.to_s
      execution_block = ExecutionBlock.new
      execution_block.strong = opts.delete(:strong)
      execution_block.limit = opts.delete(:limit)
      execution_block.queue = opts.delete(:queue)
      execution_block.meta = opts
      execution_block.block = block
      off_block = ExecutionBlock.new
      off_block.block = proc do
        off(event, execution_block)
      end
      EVENTS_QUEUE.sync do
        @events[event] ||= []
        @events[event] << execution_block
      end
      off_block
    end

    def now_and_on(event, opts={}, &block)
      rmext_block_on_main_q(block)
      on(event, opts, &block)
    end

    def off(event=nil, execution_block=nil)
      EVENTS_QUEUE.sync do
        if event.is_a?(String) || event.is_a?(Symbol)
          event = event.to_s
          if execution_block
            if events = @events[event]
              deleted = events.delete(execution_block)
              if DEBUG_EVENTS
                p "remove the one block for the event", "EVENT:", event, "deleted:", deleted
              end
            end
          else
            deleted = @events.delete(event)
            if DEBUG_EVENTS
              p "remove all blocks for the event", "EVENT:", event, "deleted:", deleted
            end
          end
        else
          @events.clear
          if DEBUG_EVENTS
            p "remove all blocks for all events"
          end
        end
      end
      nil
    end

    def trigger(event, *values)
      EVENTS_QUEUE.async do
        # if DEBUG_EVENTS
        #   p "TRIGGER:", event, values, "@events", @events
        # end
        event = event.to_s
        _execution_blocks = @events[event]
        next unless _execution_blocks
        execution_blocks = _execution_blocks.dup
        while execution_blocks.size > 0
          execution_block = execution_blocks.shift
          exclusive = execution_block.meta[:exclusive]
          if exclusive
            _exclusive = exclusive.dup
            while _exclusive.size > 0
              exclude = _exclusive.shift.to_s
              deleted = @events.delete(exclude)
              if DEBUG_EVENTS
                p "REMOVING DUE TO EXCLUSIVE:", exclude, "FOR EVENT:", event, "deleted:", deleted
              end
            end
          end
          execution_block.call(*values)
          if execution_block.dead
            deleted = _execution_blocks.delete(execution_block)
            if DEBUG_EVENTS
              p "REMOVING DUE TO DEAD:", "FOR EVENT:", event, "deleted:", deleted
            end
          end
        end
      end
      nil
    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Events)
