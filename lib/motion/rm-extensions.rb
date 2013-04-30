module RMExtensions

  # this module is included on Object, so these methods are available from anywhere in your code.
  module ObjectExtensions

    def rmext_weak_attr_accessor(*attrs)
      attrs.each do |attr|
        define_method(attr) do
          if val = instance_variable_get("@#{attr}")
            val.nonretainedObjectValue
          end
        end
        define_method("#{attr}=") do |val|
          if val
            nonretained_val = NSValue.valueWithNonretainedObject(val)
            instance_variable_set("@#{attr}", nonretained_val)
          else
            instance_variable_set("@#{attr}", val)
          end
          val
        end
      end
    end

    def rmext_assert_main_thread!
      raise "This method must be called on the main thread." unless NSThread.currentThread.isMainThread
    end

    # https://gist.github.com/mattetti/2951773
    # https://github.com/MacRuby/MacRuby/issues/152
    # blocks within blocks can be a problem with GCD (and maybe RM/MacRuby in general?).
    # these helpers make it easy to use nested blocks with GCD, and also ensures those
    # blocks will not be garbage collected until at least after they have been called.

    def rmext_on_main_q(&block)
      rmext_retained_context do |x|
        x.block = -> do
          block.call
          x.detach!
        end
        Dispatch::Queue.main.async(&x.block)
      end
    end

    def rmext_on_serial_q(q, &block)
      Dispatch.once { $serial_qs = {} }
      rmext_retained_context do |x|
        x.block = -> do
          block.call
          x.detach!
        end
        x.key = "#{NSBundle.mainBundle.bundleIdentifier}.serial.#{q}"
        $serial_qs[x.key] ||= Dispatch::Queue.new(x.key)
        $serial_qs[x.key].async(&x.block)
      end
    end

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

    # #rmext_retain! is different than a normal retain.  it adds the object(self) to a retained
    # array, utilizing RM's underlying GC logic
    #
    # you most likely want to use #rmext_retained_context and not call this directly
    #
    def rmext_retain!
      ::RMExtensions::RetainedContext.rmext_retains_queue.sync do
        ::RMExtensions::RetainedContext.rmext_retains.push(self)
      end
    end

    # #rmext_detach! is slightly similar to the concept of "release".  it removes the object(self)
    # from a retained array (only one hit, in case the same object is #rmext_retain!'d multiple times),
    # utilizing RM's underlying GC logic.  if nothing else has a strong reference to the object after
    # it is detached, it will eventually be handled by RM's GC.
    #
    # you most likely want to use #rmext_retained_context and not call this directly
    #
    def rmext_detach!
      ::RMExtensions::RetainedContext.rmext_retains_queue.async do
        ::RMExtensions::RetainedContext.rmext_retains.delete_at(::RMExtensions::RetainedContext.rmext_retains.index(self) || ::RMExtensions::RetainedContext.rmext_retains.length)
      end
    end

    # #rmext_context yields an object you can treat like an openstruct (the "context")
    def rmext_context(&block)
      ::RMExtensions::Context.create(self, &block)
    end

    # #rmext_retained_context yields an object you can treat like an openstruct.  you can get/set any
    # property on it.  the context is globally retained, until #detach! is called on the context.
    # this convention should fill the gap where local variables and scope bugs currently occur in RM,
    # and it also solves the re-entrant problem of using instance variables for retaining purposes.
    #
    # always be sure to #detach! the context at the correct place in time.
    #
    # example:
    #
    # rmext_retained_context do |x|
    #   rmext_on_serial_q("my_serial_q") do
    #     some_async_http_request do |results1|
    #       x.results1 = results1
    #       rmext_on_serial_q("my_serial_q") do
    #         some_other_async_http_request do |results2|
    #           x.results2 = results2
    #           rmext_on_main_q do
    #             p "results1", x.results1
    #             p "results2", x.results2
    #             x.detach!
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # experimental feature:
    #
    # you can call #beginBackground! on the context, and it will check-out a background task identifier,
    # and automatically end the background task when you call #detach! as normal.
    def rmext_retained_context(&block)
      ::RMExtensions::RetainedContext.create(self, &block)
    end


    def rmext_observe(object, key, &block)
      # p "+ rmext_observe", self, object, key
      wop = ::RMExtensions::WeakObserverProxy.get(self)
      rmext_observe_passive(object, key, &block)
      block.call(object.send(key)) unless block.nil?
    end

    def rmext_observe_passive(object, key, &block)
      wop = ::RMExtensions::WeakObserverProxy.get(self)
      b = -> (old_value, new_value) do
        block.call(new_value) unless block.nil?
      end
      wop.observe(object, key, &b)
    end

    def rmext_performBlockOnDealloc(block)
      internalObject = RMExtExecuteOnDeallocInternalObject.new(block)
      internalObject.obj = self
      @rmext_performBlockOnDealloc_blocks ||= {}
      @rmext_performBlockOnDealloc_blocks[internalObject] = internalObject
      nil
    end

    def rmext_cancelDeallocBlockWithKey2(blockKey)
      @rmext_performBlockOnDealloc_blocks ||= {}
      internalObject = @rmext_performBlockOnDealloc_blocks[blockKey]
      internalObject.block = nil
      @rmext_performBlockOnDealloc_blocks.delete(blockKey)
      nil
    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions)

module RMExtensions
  # You don't use these classes directly.
  class Context

    class << self
      def create(origin, &block)
        x = new
        block.call(x) unless block.nil?
        x
      end
    end

    attr_accessor :hash

    def initialize
      self.hash = {}
    end

    def method_missing(method, *args)
      m = method.to_s
      if m =~ /(.+)?=$/
        hash[$1] = args.first
      else
        hash[m]
      end
    end

  end

  class RetainedContext < Context

    class << self
      def rmext_retains
        Dispatch.once { @rmext_retains = [] }
        @rmext_retains
      end

      def rmext_retains_queue
        Dispatch.once { @rmext_retains_queue = Dispatch::Queue.new("#{NSBundle.mainBundle.bundleIdentifier}.rmext_retains_queue") }
        @rmext_retains_queue
      end

      def create(origin, &block)
        x = new
        x.hash["retained_origin"] = origin
        x.hash["retained_block"] = block
        x.rmext_retain!
        block.call(x) unless block.nil?
        x
      end
    end

    # if you provide a block, you are responsible for calling #detach!,
    # otherwise, the expiration handler will just call #detach!
    def beginBackground!(&block)
      hash["bgTaskExpirationHandler"] = block
      hash["bgTask"] = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler(-> do
        if hash["bgTaskExpirationHandler"]
          hash["bgTaskExpirationHandler"].call
        else
          detach!
        end
      end)
    end

    def detach!
      if hash["bgTask"] && hash["bgTask"] != UIBackgroundTaskInvalid
        UIApplication.sharedApplication.endBackgroundTask(hash["bgTask"])
      end
      self.hash = nil
      rmext_detach!
    end

    def detach_on_death_of(object)
      object.rmext_performBlockOnDealloc(detach_death_proc)
    end

    def detach_death_proc
      proc { |x| detach! }
    end

    def method_missing(method, *args)
      unless hash
        raise "You detached this rmext_retained_context and then called: #{method}"
      end
      super
    end

  end

  class WeakObserverProxy
    include BW::KVO
    rmext_weak_attr_accessor :obj
    attr_accessor :strong_object_id, :strong_class_name
    def initialize(strong_object)
      self.obj = strong_object
      self.strong_object_id = strong_object.object_id
      self.strong_class_name = strong_object.class.name
      self.class.weak_observer_map[strong_object_id] = self
      strong_object.rmext_performBlockOnDealloc(kill_observation_proc)
    end
    # isolate this in its own method so it wont create a retain cycle
    def kill_observation_proc
      proc { |x|
        # uncomment to verify deallocation is working.  if not, there is probably
        # a retain cycle somewhere in your code.
        # p "kill_observation_proc", self
        self.obj = nil
        unobserve_all
        self.class.weak_observer_map.delete(strong_object_id)
      }
    end
    def inspect
      "#{strong_class_name}:#{strong_object_id}"
    end
    def self.weak_observer_map
      Dispatch.once { $weak_observer_map = {} }
      $weak_observer_map
    end
    def self.get(obj)
      return obj if obj.is_a?(WeakObserverProxy)
      weak_observer_map[obj.object_id] || new(obj)
    end
  end

  class RMExtExecuteOnDeallocInternalObject
    attr_accessor :block
    rmext_weak_attr_accessor :obj
    def initialize(block)
      self.block = block
    end
    def dealloc
      if block
        block.call(obj)
        self.block = nil
      end
      super
    end
  end

end
