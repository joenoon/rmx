module RMExtensions

  module ObjectExtensions

    module Context

      # yields an object you can treat like an openstruct.  you can get/set any property
      # on it.  useful for scope issues where local variables wont work, and where instance
      # variables would clutter the object and not be re-entrant.
      def rmext_context(&block)
        ::RMExtensions::Context.create(self, &block)
      end

      # like +rmext_context+ but the context is retained (as well as anything set on it) until you
      # explicitly call +detach!+ or +detach_on_death_of+ and that object is deallocated.  prevents
      # deallocation of objects until you are done with them, for example  through asynchronous
      # operations.
      #
      # also has a useful shortcut for beginBackgroundTaskWithExpirationHandler/endBackgroundTask
      # via +begin_background!+.  when you call +detach!+ the background task will be ended for you
      # as well.
      #
      # use this over +rmext_context+ when you have a scenario when eventually you know everything
      # is complete, and can call +detach!+.  for example, an operation that makes an http request,
      # uses the result to call another operation on a specific queue, and is finally considered
      # "finished" at some point in time in the future.  there is a definitive "end", at some point
      # in the future.
      def rmext_retained_context(&block)
        ::RMExtensions::RetainedContext.create(self, &block)
      end

    end

  end

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
      def create(origin, &block)
        x = new
        # automatically retain the origin and block
        x.hash["retained_origin"] = origin
        x.hash["retained_block"] = block
        x.rmext_retain!
        block.call(x) unless block.nil?
        x
      end
    end

    # if you provide a block, you are responsible for calling #detach!,
    # otherwise, the expiration handler will just call #detach!
    def begin_background!(&block)
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
      # end the bgTask if one was created
      if hash["bgTask"] && hash["bgTask"] != UIBackgroundTaskInvalid
        UIApplication.sharedApplication.endBackgroundTask(hash["bgTask"])
      end
      self.hash = nil
      rmext_detach!
    end

    # watch some other object for deallocation, and when it does, +detach!+ self
    def detach_on_death_of(object)
      object.rmext_on_dealloc(&detach_death_proc)
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

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Context)
