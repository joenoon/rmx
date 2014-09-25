class RMX

  Dispatch.once do
    $rmx_log_deallocs = NSHashTable.weakObjectsHashTable
  end

  LOG_DEALLOC_QUEUE = Dispatch::Queue.new("rmx_log_deallocs")

  def self.logged_deallocs
    res = nil
    LOG_DEALLOC_QUEUE.sync do
      res = $rmx_log_deallocs.allObjects
    end
    res
  end

  def self.log_dealloc(object, verbose=false)
    LOG_DEALLOC_QUEUE.sync do
      $rmx_log_deallocs.addObject(object)
    end
    if verbose || DEBUG_DEALLOC
      me = object.rmx_object_desc
      NSLog("     -     INIT      - #{me}")
      object.rac_willDeallocSignal.subscribeCompleted(-> {
        NSLog("     -     DEALLOC   - #{me}")
      })
    end
    nil
  end

end
