module RMExtensions

  def self.debug?
    !!@debug
  end

  def self.debug!(bool=true)
    @debug = bool
  end

  # LongTask encapsulates beginBackgroundTaskWithExpirationHandler/endBackgroundTask:
  #
  # RMExtensions::BackgroundTask.new("my long task") do |task|
  #   do_something_long
  #   task.end!
  # end
  #
  # RMExtensions::BackgroundTask.new("my long task") do |task|
  #   do_something_long_async do
  #     # later this long task finishes...
  #     task.end!
  #   end
  # end
  #
  class LongTask
    attr_accessor :bgTask, :desc

    # RMExtensions::BackgroundTask.new("my long task") { |task| task.end! }
    def initialize(desc=nil, &block)
      @desc = desc
      @bgTask = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler(lambda do
        if ::RMExtensions.debug?
          p "ERROR: #{self.inspect} #{@desc} didn't call #end! in time!"
        end
        UIApplication.sharedApplication.endBackgroundTask(@bgTask)
      end.weak!)
      block.call(self)
      self
    end

    def end!
      if ::RMExtensions.debug?
        p "SUCCESS: #{self.inspect} #{@desc} ended successfully."
      end
      if @bgTask != UIBackgroundTaskInvalid
        UIApplication.sharedApplication.endBackgroundTask(@bgTask)
        @bgTask = UIBackgroundTaskInvalid
      end
    end

  end

  module ObjectExtensions

    module Util

      # Raises an exception when called from a thread other than the main thread.
      # Good for development and experimenting.
      def rmext_assert_main_thread!
        raise "This method must be called on the main thread." unless NSThread.currentThread.isMainThread
      end

      # Shortcut to instance_variable_get and instance_variable_get:
      # 1 arg for instance_variable_get
      # 2 args for instance_variable_set
      def rmext_ivar(*args)
        if args.size == 1
          instance_variable_get("@#{args[0]}")
        elsif args.size == 2
          instance_variable_set("@#{args[0]}", args[1])
        else
          raise "rmext_ivar called with invalid arguments: #{args.inspect}"
        end
      end

      def rmext_nil_instance_variables!
        ivars = [] + instance_variables
        while ivar = ivars.pop
          instance_variable_set(ivar, nil)
        end
        true
      end

      def rmext_assign_debug_labels_to_ivars!
        ivars = [] + instance_variables
        while ivar = ivars.pop
          val = instance_variable_get(ivar)
          val.rmext_ivar(:debug_label, ivar)
        end
        true
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Util)
