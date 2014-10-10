# RMXLongTask encapsulates beginBackgroundTaskWithExpirationHandler/endBackgroundTask:
#
# rac_signal = RMXLongTask.createSignal("my long task") do |task|
#   do_something_long
#   task.sendCompleted
# end
#
# rac_signal = RMXLongTask.createSignal("my long task") do |task|
#   do_something_long_async do
#     # later this long task finishes...
#     task.sendCompleted
#   end
# end
#
# @todo - refactor
module RMXLongTask

  def self.createSignal(desc=nil, &block)
    promise = RACReplaySubject.replaySubjectWithCapacity(1)

    NSLog("RMXLongTask CREATED: desc: #{desc}") if desc && RMX::DEBUG_LONGTASK

    bgTask = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler(-> {
      NSLog("RMXLongTask EXPIRED!: bgTask: #{bgTask}, desc: #{desc}") if desc
      promise.sendCompleted
    })

    promise.take(1).subscribeCompleted(-> {
      if bgTask && bgTask != UIBackgroundTaskInvalid
        NSLog("RMXLongTask END: bgTask: #{bgTask}, desc: #{desc}") if desc && RMX::DEBUG_LONGTASK
        UIApplication.sharedApplication.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
      else
        NSLog("RMXLongTask END INVALID: bgTask: #{bgTask}, desc: #{desc}") if desc && RMX::DEBUG_LONGTASK
      end
      NSLog("RMXLongTask BACKGROUND TIME REMAINING: #{time_remaining}") if RMX::DEBUG_LONGTASK
    })

    block.call(promise)
    
    promise
  end

  def self.time_remaining
    UIApplication.sharedApplication.backgroundTimeRemaining
  end

end
