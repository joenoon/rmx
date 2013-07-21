module RMExtensions

  module ObjectExtensions

    module Observation

      def rmext_observation_proxy
        @rmext_observation_proxy ||= ObservationProxy.new(self.inspect)
      end

      # observe an object.key. takes a block that will be called with the
      # new value upon change.
      #
      # rmext_observe_passive(@model, "name") do |val|
      #   p "name is #{val}"
      # end
      def rmext_observe_passive(object, key, &block)
        rmext_observation_proxy.observe(object, key, &block)
      end

      # like +rmext_observe_passive+ but additionally fires the callback immediately.
      def rmext_observe(object, key, &block)
        rmext_observe_passive(object, key, &block)
        block.call(object.send(key)) unless block.nil?
      end

      # unobserve an existing observation
      def rmext_unobserve(object, key)
        if @rmext_observation_proxy
          @rmext_observation_proxy.unobserve(object, key)
        end
      end

      # unobserve all existing observations
      def rmext_unobserve_all
        if @rmext_observation_proxy
          @rmext_observation_proxy.unobserve_all
        end
      end

      def on(event, &block)
        rmext_observation_proxy.on(event, &block)
      end

      def off(event, &block)
        if @rmext_observation_proxy
          @rmext_observation_proxy.off(event, &block)
        end
      end

      def off_all
        if @rmext_observation_proxy
          @rmext_observation_proxy.off_all
        end
      end

      def trigger(event, *args)
        if @rmext_observation_proxy
          @rmext_observation_proxy.trigger(event, *args)
        end
      end

    end

  end

  # # Proxy class used to hold the actual observation and watches for the real
  # # class intended to hold the observation to be deallocated, so the
  # # observation can be cleaned up.
  class ObservationProxy
    COLLECTION_OPERATIONS = [ NSKeyValueChangeInsertion, NSKeyValueChangeRemoval, NSKeyValueChangeReplacement ]
    DEFAULT_OPTIONS = NSKeyValueObservingOptionNew

    def initialize(desc)
      @desc = desc
      @events = {}
      @targets = {}
      # p "created #{self.inspect} for #{@desc}"
    end

    def dealloc
      p "dealloc #{self.inspect} for #{@desc}"
      unobserve_all
      off_all
      super
    end

    def observe(target, key_path, &block)
      target.addObserver(self, forKeyPath:key_path, options:DEFAULT_OPTIONS, context:nil) unless registered?(target, key_path)
      add_observer_block(target, key_path, &block)
    end

    def unobserve(target, key_path)
      return unless registered?(target, key_path)
      target.removeObserver(self, forKeyPath:key_path)
      remove_observer_block(target, key_path)
    end

    def remove_observer_block(target, key_path)
      return if target.nil? || key_path.nil?

      key_paths = @targets[target]
      if !key_paths.nil? && key_paths.has_key?(key_path.to_s)
        key_paths.delete(key_path.to_s)
      end
    end

    def unobserve_all
      keys = @targets.keys.clone
      while keys.size > 0
        target = keys.pop
        target_hash = @targets[target]
        paths = target_hash.keys.clone
        while paths.size > 0
          key_path = paths.pop
          target.removeObserver(self, forKeyPath:key_path)
        end
      end
      @targets.clear
    end

    def registered?(target, key_path)
      !target.nil? && !@targets[target].nil? && @targets[target].has_key?(key_path.to_s)
    end

    def add_observer_block(target, key_path, &block)
      return if target.nil? || key_path.nil? || block.nil?
      @targets[target] ||= {}
      @targets[target][key_path.to_s] ||= []
      @targets[target][key_path.to_s] << block
    end

    # NSKeyValueObserving Protocol

    def observeValueForKeyPath(key_path, ofObject:target, change:change, context:context)
      return if target.nil?
      key_paths = @targets[target] || {}
      blocks = key_paths[key_path] || []
      blocks.each do |block|
        args = [ change[NSKeyValueChangeNewKey] ]
        args << change[NSKeyValueChangeIndexesKey] if collection?(change)
        block.call(*args)
      end
    end

    def collection?(change)
      COLLECTION_OPERATIONS.include?(change[NSKeyValueChangeKindKey])
    end

    def on(event, &block)
      return if event.nil? || block.nil?
      @events[event.to_s] ||= []
      @events[event.to_s] << block
    end

    def off(event, &block)
      return if event.nil? || block.nil? || !@events.key?(event.to_s)
      @events[event.to_s].delete_if { |b| b == block }
      nil
    end

    def off_all
      @events.clear
    end

    def trigger(event, *args)
      return if event.nil? || !@events.key?(event.to_s)
      @events[event.to_s].each do |block|
        block.call(*args)
      end
      nil
    end
  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Observation)
