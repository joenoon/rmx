module RMExtensions

  module ObjectExtensions

    module Observation

      # observe an object.key. takes a block that will be called with the
      # new value upon change.
      #
      # rmext_observe_passive(@model, "name") do |val|
      #   p "name is #{val}"
      # end
      def rmext_observe_passive(object, key, &block)
        @__observation_proxy__ ||= ObservationProxy.new
        @__observation_proxy__.observe(object, key, &block)
      end

      # like +rmext_observe_passive+ but additionally fires the callback immediately.
      def rmext_observe(object, key, &block)
        rmext_observe_passive(object, key, &block)
        block.call(object.send(key)) unless block.nil?
      end

      # unobserve an existing observation
      def rmext_unobserve(object, key)
        if @__observation_proxy__
          @__observation_proxy__.unobserve(object, key)
        end
      end

      # unobserve all existing observations
      def rmext_unobserve_all
        if @__observation_proxy__
          @__observation_proxy__.unobserve_all
        end
      end

      def on(event, &block)
        @__observation_proxy__ ||= ObservationProxy.new
        @__observation_proxy__.on(event, &block)
      end

      def off(event, &block)
        if @__observation_proxy__
          @__observation_proxy__.off(event, &block)
        end
      end

      def off_all
        if @__observation_proxy__
          @__observation_proxy__.off_all
        end
      end

      def trigger(event, *args)
        if @__observation_proxy__
          @__observation_proxy__.trigger(event, *args)
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

    def initialize
      @object_map = {}
      @events = {}
      @targets = {}
    end

    def dealloc
      p "ObservationProxy dealloc!"
      unobserve_all
      off_all
      super
    end

    def observe(target, key_path, &block)
      target_id = object_id_for_object(target)
      target.addObserver(self, forKeyPath:key_path, options:DEFAULT_OPTIONS, context:nil) unless registered?(target_id, key_path)
      add_observer_block(target_id, key_path, &block)
    end

    def unobserve(target, key_path)
      target_id = object_id_for_object(target)
      return unless registered?(target_id, key_path)
      target.removeObserver(self, forKeyPath:key_path)
      remove_observer_block(target_id, key_path)
    end

    def remove_observer_block(target_id, key_path)
      return if target_id.nil? || key_path.nil?

      key_paths = @targets[target_id]
      if !key_paths.nil? && key_paths.has_key?(key_path.to_s)
        key_paths.delete(key_path.to_s)
      end
    end

    def unobserve_all
      keys = @targets.keys.clone
      while keys.size > 0
        k = keys.pop
        t = @targets[k]
        paths = t.keys.clone
        while paths.size > 0
          key_path = paths.pop
          if target = object_for_object_id(k)
            target.removeObserver(self, forKeyPath:key_path)
          end
        end
      end
      @targets.clear
    end

    def object_id_for_object(object)
      @object_map[object.object_id] = object
      object.object_id
    end

    def object_for_object_id(obj_id)
      @object_map[obj_id]
    end

    def registered?(target_id, key_path)
      !target_id.nil? && !@targets[target_id].nil? && @targets[target_id].has_key?(key_path.to_s)
    end

    def add_observer_block(target_id, key_path, &block)
      return if target_id.nil? || key_path.nil? || block.nil?
      @targets[target_id] ||= {}
      @targets[target_id][key_path.to_s] ||= []
      @targets[target_id][key_path.to_s] << block
    end

    # NSKeyValueObserving Protocol

    def observeValueForKeyPath(key_path, ofObject:target, change:change, context:context)
      target_id = object_id_for_object(target)
      return if target_id.nil?
      key_paths = @targets[target_id] || {}
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
