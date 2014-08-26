# RMXLongTask encapsulates beginBackgroundTaskWithExpirationHandler/endBackgroundTask:
#
# RMXLongTask.new("my long task") do |task|
#   do_something_long
#   task.end!
# end
#
# RMXLongTask.new("my long task") do |task|
#   do_something_long_async do
#     # later this long task finishes...
#     task.end!
#   end
# end
#
class RMXLongTask
  attr_accessor :bgTask, :desc

  include RMXCommonMethods

  def self.time_remaining
    UIApplication.sharedApplication.backgroundTimeRemaining
  end

  def self.when_all_complete(&block)
    Dispatch::Queue.main.async do
      if RMXLongTask.outstanding_tasks.size.zero?
        RMX.block_on_main_q(block)
      else
        RMX.new(RMXLongTask).once(:all_complete) do
          block.call
        end
      end
    end
  end

  def self.outstanding_queue
    Dispatch.once do
      @outstanding_queue = Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.outstanding.LongTask")
    end
    @outstanding_queue
  end

  def self.outstanding_tasks
    Dispatch.once do
      @outstanding_tasks = []
    end
    @outstanding_tasks
  end

  # RMXLongTask.verbose("my long task") { |task| task.end! }
  def self.verbose(desc=nil, &block)
    _creator(desc, true, true, &block)
  end

  # RMXLongTask.create("my long task") { |task| task.end! }
  def self.create(desc=nil, &block)
    _creator(desc, false, true, &block)
  end

  def self.internal(desc=nil, &block)
    _creator(desc, false, false, &block)
  end

  def self._creator(desc=nil, verbose=false, tracking=true, &block)
    x = new(desc, verbose, tracking)
    block.weak!.call(x)
    x
  end

  def self.reset_outstanding_tasks!
    RMXLongTask.outstanding_queue.sync do
      size = RMXLongTask.outstanding_tasks.size
      if size > 0
        p "WARNING: reset_outstanding_tasks! (was: #{size})"
        RMXLongTask.outstanding_tasks.removeAllObjects
      end
    end
  end

  def initialize(desc=nil, verbose=false, tracking=true)
    @verbose = verbose
    @tracking = tracking
    @desc = "#{rmx_object_desc} #{desc}"
    @bgTask = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler(lambda do
      p "ERROR: #{@desc} didn't call #end! in time!"
      __end!
    end)
    if RMX::DEBUG_LONGTASK || @verbose
      p "CREATED: #{@desc}"
    end
    if @tracking
      RMXLongTask.outstanding_queue.sync do
        RMXLongTask.outstanding_tasks << self
      end
    end
    self
  end

  def end!
    if RMX::DEBUG_LONGTASK || @verbose
      p "SUCCESS: #{@desc} ended successfully."
    end
    __end!
  end

  def __end!
    if @tracking
      RMXLongTask.outstanding_queue.sync do
        RMXLongTask.outstanding_tasks.delete(self)
        RMXLongTask.internal("check for all complete") do |internal_task|
          Dispatch::Queue.main.async do
            if RMXLongTask.outstanding_tasks.size.zero?
              RMX.new(RMXLongTask).trigger(:all_complete)
            end
            internal_task.end!
          end
        end
      end
    end
    if @bgTask && @bgTask != UIBackgroundTaskInvalid
      UIApplication.sharedApplication.endBackgroundTask(@bgTask)
      @bgTask = UIBackgroundTaskInvalid
    end
  end

  def rmx_object_desc
    "#{super}<#{@desc}>"
  end

end
