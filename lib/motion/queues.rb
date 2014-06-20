module RMExtensions

  # A hash used by +rmext_on_serial_q+ storing created serial queues, so they
  # are not instantiated each time they are used.
  def self.serial_qs
    Dispatch.once { @serial_qs = {} }
    @serial_qs
  end

  module ObjectExtensions

    # These helper methods are all for async mode.
    module Queues

      # execute a block on the main queue, asynchronously.
      def rmext_on_main_q(&block)
        Dispatch::Queue.main.async(&block)
      end

      # execute a block on a serial queue, asynchronously.
      def rmext_on_serial_q(q, &block)
        key = "#{NSBundle.mainBundle.bundleIdentifier}.serial.#{q}"
        ::RMExtensions.serial_qs[key] ||= Dispatch::Queue.new(key)
        ::RMExtensions.serial_qs[key].async(&block)
      end

      # execute a block on a concurrent queue, asynchronously.
      def rmext_on_concurrent_q(q, &block)
        key = "#{NSBundle.mainBundle.bundleIdentifier}.concurrent.#{q}"
        Dispatch::Queue.concurrent(key).async(&block)
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Queues)
