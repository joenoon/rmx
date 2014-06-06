module RMExtensions

  module ObjectExtensions

    module Events

      ASYNC_QUEUE = Dispatch::Queue.new("RMX.events.async_queue")
      LOCK = NSRecursiveLock.new

      # register a callback when an event is triggered on this object.
      def rmext_on(event, _opts={}, &block)
        raise "rmext_on event required" if event.nil?
        opts = _opts.dup
        if block.nil?
          block = proc {}
        end
        event = event.to_s
        if DEBUG_EVENTS
          p "ON:", event, "opts:", opts
        end
        block_owner = block.owner
        weak_block_owner = block_owner.respond_to?(:weakref_alive?) ? block_owner : WeakRef.new(block_owner)
        if opts[:strong]
          opts[:strong] = [ self, block_owner ]
        else
          # p "MAKE BLOCK WEAK:", event, "opts:", opts
          block.weak!
        end
        opts[:limit] ||= -1
        opts[:block_owner] = weak_block_owner
        LOCK.lock
        if block
          @rmext_events ||= {}
          blocks = @rmext_events[event] ||= {}
          blocks[block] = opts
        end
        LOCK.unlock
        block_owner.rmext_noop_on_main
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
        return unless @rmext_events
        LOCK.lock
        if event.is_a?(String) || event.is_a?(Symbol)
          event = event.to_s
          if block
            if blocks = @rmext_events[event]
              if DEBUG_EVENTS
                p "remove the one block for the event in the blocks #owner", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", blocks
              end
              block_keys = blocks.keys.dup
              while block_keys.size > 0
                blk = block_keys.shift
                opts = blocks[blk]
                block_owner = opts[:block_owner]
                unless block_owner.weakref_alive? && blk
                  if DEBUG_EVENTS
                    p "cleanup: stale block"
                  end
                  blocks.delete(blk)
                  next
                end
                if blk == block
                  if DEBUG_EVENTS
                    p "delete: matching block"
                  end
                  blocks.delete(blk)
                end
              end
            end
          elsif context
            if blocks = @rmext_events[event]
              if DEBUG_EVENTS
                p "remove all handlers for the given event in the given context", "EVENT:", event, "CONTEXT:", context.rmext_object_desc, "BLOCKS:", context_events
              end
              block_keys = blocks.keys.dup
              while block_keys.size > 0
                blk = block_keys.shift
                opts = blocks[blk]
                block_owner = opts[:block_owner]
                unless block_owner.weakref_alive? && blk
                  if DEBUG_EVENTS
                    p "cleanup: stale block"
                  end
                  blocks.delete(blk)
                  next
                end
                if block_owner == context
                  if DEBUG_EVENTS
                    p "delete: matching context"
                  end
                  blocks.delete(blk)
                end
              end
            end
          else
            if DEBUG_EVENTS
              p "remove all handlers for the event in all contexts known", "EVENT:", event
            end
            @rmext_events.delete event
          end
        elsif event
          context = event
          if DEBUG_EVENTS
            p "event is really a context. remove all events and handlers for the context", "CONTEXT:", context.rmext_object_desc
          end
          event_keys = @rmext_events.keys.dup
          while event_keys.size > 0
            e = event_keys.shift
            rmext_off(e, context)
          end
        else
          if DEBUG_EVENTS
            p "remove all events"
          end
          @rmext_events.clear
        end
        LOCK.unlock
        nil
      end

      # trigger an event with value on this object
      def rmext_trigger(event, *values)
        return unless @rmext_events
        LOCK.lock
        event = event.to_s
        blocks = @rmext_events[event]
        if DEBUG_EVENTS
          blocks_size = blocks ? blocks.size : 0
          p "TRIGGER:", event, @rmext_events, "OBJECT:", self.rmext_object_desc, "BLOCKS SIZE:", blocks_size
        end
        if blocks
          block_keys = blocks.keys.dup
          while block_keys.size > 0
            blk = block_keys.shift
            opts = blocks[blk]
            if exclusive = opts[:exclusive]
              _exclusive = exclusive.dup
              while _exclusive.size > 0
                exclude = _exclusive.shift
                if DEBUG_EVENTS
                  p "REMOVING DUE TO EXCLUSIVE:", exclude, "FOR EVENT:", event
                end
                rmext_off(exclude)
              end
            end
            block_owner = opts[:block_owner]
            weak_self = WeakRef.new(self)
            unless block_owner.weakref_alive? && blk
              if DEBUG_EVENTS
                p "cleanup: stale block"
              end
              blocks.delete(blk)
              next
            end
            limit = opts[:limit]
            if limit == 1
              # off
              if DEBUG_EVENTS
                p "LIMIT REACHED:", event, "OBJECT:", self.rmext_object_desc, "CONTEXT:", opts[:block_owner].rmext_object_desc
              end
              blocks.delete(blk)
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
            values.rmext_noop_on_main
            rmext_noop_after_async_q(queue) do
              if weak_self.weakref_alive? && block_owner.weakref_alive? && blk
                blk.call(*values)
                block_owner.rmext_noop_on_main
                values.rmext_noop_on_main
                blk = nil
              end
            end
          end
        end
        LOCK.unlock
        nil
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Events)
