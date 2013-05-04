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
        wop = ::RMExtensions::WeakObserverProxy.get(self)
        b = -> (old_value, new_value) do
          block.call(new_value) unless block.nil?
        end
        wop.observe(object, key, &b)
      end

      # like +rmext_observe_passive+ but additionally fires the callback immediately.
      def rmext_observe(object, key, &block)
        # p "+ rmext_observe", self, object, key
        rmext_observe_passive(object, key, &block)
        block.call(object.send(key)) unless block.nil?
      end

      # unobserve an existing observation
      def rmext_unobserve(object, key)
        wop = ::RMExtensions::WeakObserverProxy.get(self)
        wop.unobserve(object, key)
        wop.clear_empty_targets!
      end

      # unobserve all existing observations
      def rmext_unobserve_all
        wop = ::RMExtensions::WeakObserverProxy.get(self)
        wop.unobserve_all
      end

    end

  end

  # Proxy class used to hold the actual observation and watches for the real
  # class intended to hold the observation to be deallocated, so the
  # observation can be cleaned up.
  class WeakObserverProxy
    include BW::KVO
    rmext_weak_attr_accessor :obj
    attr_accessor :strong_object_id, :strong_class_name
    def initialize(strong_object)
      self.obj = strong_object
      self.strong_object_id = strong_object.object_id
      self.strong_class_name = strong_object.class.name
      self.class.weak_observer_map[strong_object_id] = self
      strong_object.rmext_on_dealloc(&kill_observation_proc)
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
    # get rid of targets that dont contain anything to avoid retain cycles.
    def clear_empty_targets!
      return if @targets.nil?
      @targets.each_pair do |target, key_paths|
        if !key_paths || key_paths.size == 0
          @targets.delete(target)
        end
      end
      nil
    end
    def inspect
      "#{strong_class_name}:#{strong_object_id}"
    end
    def targets
      @targets
    end
    def self.weak_observer_map
      Dispatch.once { @weak_observer_map = {} }
      @weak_observer_map
    end
    def self.get(obj)
      return obj if obj.is_a?(WeakObserverProxy)
      weak_observer_map[obj.object_id] || new(obj)
    end
  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Observation)
