# Subclass of NSOperation
# Usage:
#   1. subclass RMXConcurrentOperation
#   2. implement #run, do your stuff here
#   3. call #done! when your operation should be marked done
#   4. throughout a long/async operation, make heavy use of
#      return/next/break if #done? to abort if cancelled from the outside
#   5. use #time_elapsed if you want to get the seconds since started
class RMXConcurrentOperation < NSOperation

  include RMXCommonMethods
  include RMXSetAttributes

  def init
    s = super
    RMX(self).sync_ivar(:start_time, Time.now)
    RMX(self).sync_ivar(:isExecuting, false)
    RMX(self).sync_ivar(:isFinished, false)
    s
  end

  def start
    self.isExecuting = true
    run
  end

  def run
    raise "unimplemented #run"
  end

  def isExecuting=(bool)
    RMX(self).kvo_sync_ivar(:isExecuting, bool)
  end

  def isFinished=(bool)
    RMX(self).kvo_sync_ivar(:isFinished, bool)
  end

  def isExecuting
    RMX(self).sync_ivar(:isExecuting)
  end

  def isFinished
    RMX(self).sync_ivar(:isFinished)
  end

  def isConcurrent
    true
  end

  def done?
    isCancelled || isFinished
  end

  def cancel!
    self.isCancelled = true
    self.isFinished = true
  end

  def done!
    self.isFinished = true
  end

  def time_elapsed
    start_time = RMX(self).sync_ivar(:start_time)
    Time.now - start_time
  end

end
