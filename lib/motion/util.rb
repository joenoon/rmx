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

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Util)
