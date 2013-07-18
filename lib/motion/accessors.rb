module RMExtensions

  module ObjectExtensions

    module Accessors

      # creates an +attr_accessor+ like behavior, but the objects are
      # stored with a WeakRef.
      # does not conform to KVO like attr_accessor does.
      def rmext_weak_attr_accessor(*attrs)
        attrs.each do |attr|
          define_method(attr) do
            instance_variable_get("@#{attr}")
          end
          define_method("#{attr}=") do |val|
            instance_variable_set("@#{attr}", WeakRef.new(val))
            val
          end
        end
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Accessors)
