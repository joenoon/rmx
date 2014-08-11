# Proxy class used to hold the actual handlers and contexts of handlers.
# When the real class deallocates, all handlers are removed.
class RMXEventsFromProxy

  QUEUE = Dispatch::Queue.new("RMXEventsFromProxy")

  def initialize
    @events = {}
  end

  # def rmx_dealloc
  #   off
  #   super
  # end

  def on(event, opts={}, &block)
    block ||= proc {}
    event = event.to_s
    execution_block = RMXExecutionBlock.new
    execution_block.strong = opts.delete(:strong)
    execution_block.limit = opts.delete(:limit)
    execution_block.queue = opts.delete(:queue)
    execution_block.meta = opts
    execution_block.block = block
    off_block = RMXExecutionBlock.new
    off_block.block = proc do
      off(event, execution_block)
    end
    RMX.synchronized do
      @events[event] ||= []
      @events[event] << execution_block
    end
    off_block
  end

  def now_and_on(event, opts={}, &block)
    RMX.block_on_main_q(block)
    on(event, opts, &block)
  end

  def off(event=nil, execution_block=nil)
    RMX.synchronized do
      if event.is_a?(String) || event.is_a?(Symbol)
        event = event.to_s
        if execution_block
          if events = @events[event]
            deleted = events.delete(execution_block)
            if RMX::DEBUG_EVENTS
              p "remove the one block for the event", "EVENT:", event, "deleted:", deleted
            end
          end
        else
          deleted = @events.delete(event)
          if RMX::DEBUG_EVENTS
            p "remove all blocks for the event", "EVENT:", event, "deleted:", deleted
          end
        end
      else
        @events.clear
        if RMX::DEBUG_EVENTS
          p "remove all blocks for all events"
        end
      end
    end
    nil
  end

  def trigger(event, *values)
    RMX.synchronized do
      # if RMX::DEBUG_EVENTS
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
            if RMX::DEBUG_EVENTS
              p "REMOVING DUE TO EXCLUSIVE:", exclude, "FOR EVENT:", event, "deleted:", deleted
            end
          end
        end
        execution_block.call(*values)
        if execution_block.dead
          deleted = _execution_blocks.delete(execution_block)
          if RMX::DEBUG_EVENTS
            p "REMOVING DUE TO DEAD:", "FOR EVENT:", event, "deleted:", deleted
          end
        end
      end
    end
    nil
  end

end

