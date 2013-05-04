module RMExtensions

  module ObjectExtensions

    module Accessors

      # creates an +attr_accessor+ like behavior, but the objects are stored with
      # a weak reference (OBJC_ASSOCIATION_ASSIGN).  useful to avoid retain cycles
      # when you want to have access to an object in a place that isnt responsible
      # for that object's lifecycle.
      # does not conform to KVO like attr_accessor does.
      def rmext_weak_attr_accessor(*attrs)
        attrs.each do |attr|
          define_method(attr) do
            rmext_associatedValueForKey(attr.to_sym)
          end
          define_method("#{attr}=") do |val|
            rmext_weaklyAssociateValue(val, withKey: attr.to_sym)
            val
          end
        end
      end

      # creates an +attr_accessor+ like behavior, but the objects are stored with
      # OBJC_ASSOCIATION_COPY.
      # does not conform to KVO like attr_accessor does.
      def rmext_copy_attr_accessor(*attrs)
        attrs.each do |attr|
          define_method(attr) do
            rmext_associatedValueForKey(attr.to_sym)
          end
          define_method("#{attr}=") do |val|
            rmext_atomicallyAssociateCopyOfValue(val, withKey: attr.to_sym)
            val
          end
        end
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Accessors)
