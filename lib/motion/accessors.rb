module RMExtensions

  module ObjectExtensions

    module Accessors

      # # creates an +attr_accessor+ like behavior, but the objects are
      # # stored with a WeakRef.
      # # does not conform to KVO like attr_accessor does.
      # def rmext_weak_attr_accessor(*attrs)
      #   attrs.each do |attr|
      #     define_method(attr) do
      #       instance_variable_get("@#{attr}")
      #     end
      #     define_method("#{attr}=") do |val|
      #       instance_variable_set("@#{attr}", val.nil? ? nil : WeakRef.new(val))
      #       val
      #     end
      #   end
      # end

      # creates an +attr_accessor+ like behavior, but the objects are
      # stored in an NSMapTable with strong keys (the attrs) and
      # weak values.  If the value deallocates, it becomes nil, unlike
      # a traditional WeakRef.
      # does not conform to KVO like attr_accessor does.
      def rmext_zeroing_weak_attr_accessor(*attrs)
        attrs.each do |attr|
          define_method(attr) do
            if @__zeroing_weak_holders
              @__zeroing_weak_holders.objectForKey(attr)
            end
          end
          define_method("#{attr}=") do |val|
            @__zeroing_weak_holders ||= NSMapTable.strongToWeakObjectsMapTable
            @__zeroing_weak_holders.setObject(val, forKey:attr)
            val
          end
        end
      end
      alias_method :rmext_weak_attr_accessor, :rmext_zeroing_weak_attr_accessor

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Accessors)
