module RMExtensions

  module ObjectExtensions

    module Events

      SYNC_QUEUE = Dispatch::Queue.new("RMX.events.sync_queue")
      ASYNC_QUEUE = Dispatch::Queue.new("RMX.events.async_queue")

      def rmext_events
        rmext_require_queue!(SYNC_QUEUE, __FILE__, __LINE__) if DEBUG_QUEUES
        @rmext_events ||= {}
      end

      # register a callback when an event is triggered on this object.
      def rmext_on(event, opts={}, &block)
        SYNC_QUEUE.sync do
          next if event.nil? || block.nil?
          event = event.to_s
          if DEBUG_EVENTS
            p "ON:", event, "opts:", opts
          end
          weak_block_owner = WeakRef.new(block.owner)
          block.weak!
          opts[:limit] ||= -1
          opts[:block_owner] = weak_block_owner
          opts[:unprotected_block] = block
          protected_block = proc do |*args|
            if weak_block_owner.weakref_alive?
              weak_block_owner.retain
              block.call(*args)
              weak_block_owner.autorelease
            end
          end.weak!
          opts[:protected_block] = protected_block
          blocks = rmext_events[event] ||= []
          blocks << opts.dup
        end
      end

      def rmext_now_and_on(event, opts={}, &block)
        rmext_block_on_main_q(block)
        rmext_on(event, opts, &block)
      end

      # register a callback when an event is triggered on this object and remove it after it fires once
      def rmext_once(event, opts={}, &block)
        opts[:limit] = 1
        rmext_on(event, opts, &block)
      end

      # @model.rmext_off(:fire, self)      # remove :fire in context "self"
      # @model.rmext_off(:fire, &block)    # remove :fire for specific handler
      # @model.rmext_off(:fire)            # remove all :fire in all knowns contexts
      # @model.rmext_off(self)             # remove all events in context "self"
      # @model.rmext_off                   # remove all events in all known contexts
      def rmext_off(event=nil, context=nil, &block)
        SYNC_QUEUE.sync do
          if event.is_a?(String) || event.is_a?(Symbol)
            event = event.to_s
            if block
              if blocks = rmext_events[event]
                if DEBUG_EVENTS
                  p "remove the one block for the event in the blocks #owner", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", blocks
                end
                blocks.dup.each do |opts|
                  unless opts[:block_owner].weakref_alive?
                    if DEBUG_EVENTS
                      p "cleanup: stale block"
                    end
                    blocks.delete(opts)
                    next
                  end
                  if opts[:unprotected_block] == block
                    if DEBUG_EVENTS
                      p "delete: matching block"
                    end
                    blocks.delete(opts)
                  end
                end
              end
            elsif context
              if blocks = rmext_events[event]
                if DEBUG_EVENTS
                  p "remove all handlers for the given event in the given context", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", context_events
                end
                blocks.dup.each do |opts|
                  unless opts[:block_owner].weakref_alive?
                    if DEBUG_EVENTS
                      p "cleanup: stale block"
                    end
                    blocks.delete(opts)
                    next
                  end
                  if opts[:block_owner] == context
                    if DEBUG_EVENTS
                      p "delete: matching context"
                    end
                    blocks.delete(opts)
                  end
                end
              end
            else
              if DEBUG_EVENTS
                p "remove all handlers for the event in all contexts known", "EVENT:", event
              end
              rmext_events.delete event
            end
          elsif event
            context = event
            if DEBUG_EVENTS
              p "event is really a context. remove all events and handlers for the context", "CONTEXT:", context.rmext_object_desc
            end
            rmext_events.keys.dup.each do |e|
              rmext_off(e, context)
            end
          else
            if DEBUG_EVENTS
              p "remove all events"
            end
            rmext_events.clear
          end
          nil
        end

      end

      # trigger an event with value on this object
      def rmext_trigger(event, *values)
        SYNC_QUEUE.sync do
          next if event.nil?
          event = event.to_s
          blocks = rmext_events[event]
          if DEBUG_EVENTS
            blocks_size = blocks ? blocks.size : 0
            p "TRIGGER:", event, rmext_events, "OBJECT:", self.rmext_object_desc, "BLOCKS SIZE:", blocks_size
          end
          next unless blocks
          blocks.dup.each do |opts|
            unless opts[:block_owner].weakref_alive?
              if DEBUG_EVENTS
                p "cleanup: stale block"
              end
              blocks.delete(opts)
              next
            end
            limit = opts[:limit]
            if limit == 1
              # off
              if DEBUG_EVENTS
                p "LIMIT REACHED:", event, "OBJECT:", self.rmext_object_desc, "CONTEXT:", opts[:block_owner].rmext_object_desc
              end
              blocks.delete(opts)
            elsif limit > 1
              opts[:limit] -= 1
            end
            queue = opts[:queue]
            context = opts[:block_owner]
            if queue == :async
              queue = ASYNC_QUEUE
            elsif queue == :main
              queue = Dispatch::Queue.main
            end
            queue ||= Dispatch::Queue.main
            blk = opts[:protected_block]
            queue.barrier_async do
              blk.call(*values)
              blk = nil
            end
          end
        end
        nil
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Events)
