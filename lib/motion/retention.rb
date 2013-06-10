module RMExtensions

  # A retained array, which will hold other objects we want retained.
  def self.retained_items
    # Dispatch.once { @retained_items = [] }
    # @retained_items
    # FIXME: http://hipbyte.myjetbrains.com/youtrack/issue/RM-134
    @retained_items ||= []
  end

  # A serial queue to perform all retain/detach operations on, to ensure we are always modifying
  # +retained_items+ on the same thread.
  def self.retains_queue
    # Dispatch.once { @retains_queue = Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.rmext_retains_queue") }
    # @retains_queue
    # FIXME: http://hipbyte.myjetbrains.com/youtrack/issue/RM-134
    @retains_queue ||= Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.rmext_retains_queue")
  end

  module ObjectExtensions

    module Retention

      # adds +self+ to +retained_items+.  this ensures +self+ will be retained at least
      # until +self+ is removed from +retained_items+ by calling +rmext_detach!+
      def rmext_retain!
        ::RMExtensions.retains_queue.sync do
          ::RMExtensions.retained_items.push(self)
        end
      end

      # removes one instance of +self+ from +retained_items+.  if +rmext_retain!+ has been called
      # multiple times on an object, +rmext_detach!+ must be called an equal number of times for
      # it to be completely removed from +retained_items+.  even after the object is completely
      # out of +retained_items+, it may still be retained in memory if there are strong references
      # to it anywhere else in your code.
      def rmext_detach!
        ::RMExtensions.retains_queue.async do
          ::RMExtensions.retained_items.delete_at(::RMExtensions.retained_items.index(self) || ::RMExtensions.retained_items.length)
        end
      end
      alias_method :rmext_release!, :rmext_detach!

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Retention)
