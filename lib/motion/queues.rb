module RMExtensions

  # A hash used by +rmext_on_serial_q+ storing created serial queues, so they
  # are not instantiated each time they are used.
  def self.serial_qs
    Dispatch.once { @serial_qs = {} }
    @serial_qs
  end

  module ObjectExtensions

    # Wrapper methods to work around some bugs with GCD and blocks and how the compiler
    # handles them.  See here for more information:
    #
    # https://gist.github.com/mattetti/2951773
    # https://github.com/MacRuby/MacRuby/issues/152
    # blocks within blocks can be a problem with GCD (and maybe RM/MacRuby in general?).
    # these helpers make it easy to use nested blocks with GCD, and also ensures those
    # blocks will not be garbage collected until at least after they have been called.
    #
    # Also has the added benefit of ensuring your block is retained at least until
    # it's been executed on the queue used.
    #
    # These helper methods are all for async mode.
    module Queues

      # execute a block on the main queue, asynchronously.
      def rmext_on_main_q(&block)
        rmext_retained_context do |x|
          x.block = -> do
            block.call
            x.detach!
          end
          Dispatch::Queue.main.async(&x.block)
        end
      end

      # execute a block on a serial queue, asynchronously.
      def rmext_on_serial_q(q, &block)
        rmext_retained_context do |x|
          x.block = -> do
            block.call
            x.detach!
          end
          x.key = "#{NSBundle.mainBundle.bundleIdentifier}.serial.#{q}"
          ::RMExtensions.serial_qs[x.key] ||= Dispatch::Queue.new(x.key)
          ::RMExtensions.serial_qs[x.key].async(&x.block)
        end
      end

      # execute a block on a concurrent queue, asynchronously.
      def rmext_on_concurrent_q(q, &block)
        rmext_retained_context do |x|
          x.block = -> do
            block.call
            x.detach!
          end
          x.key = "#{NSBundle.mainBundle.bundleIdentifier}.concurrent.#{q}"
          Dispatch::Queue.concurrent(x.key).async(&x.block)
        end
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Queues)
