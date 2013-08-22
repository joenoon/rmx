module RMExtensions

  def self.debug?
    !!@debug
  end

  def self.debug!(bool=true)
    @debug = bool
  end

  module ObjectExtensions

    module Util

      # Raises an exception when called from a thread other than the main thread.
      # Good for development and experimenting.
      def rmext_assert_main_thread!
        raise "This method must be called on the main thread." unless NSThread.currentThread.isMainThread
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Util)
