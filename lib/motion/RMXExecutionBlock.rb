class RMXExecutionBlock
  attr_accessor :queue, :the_block, :dead, :desc, :strong, :meta, :limit
  RMX.new(self).weak_attr_accessor :block_owner

  def block=(_block)
    self.block_owner = _block.owner
    self.the_block = RMX.safe_block(_block)
  end

  def actual_queue
    q = queue
    if q == :async
      q = RMXEventsFromProxy::QUEUE
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

