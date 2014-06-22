module RMExtensions

  def self.safe_block(block)
    weak_block_owner_holder = WeakHolder.new(block.owner)
    block.weak!
    proc do |*args|
      if wbo = weak_block_owner_holder.value
        block.call(*args)
      end
    end
  end

  module ObjectExtensions

    module Accessors

      CREATE_WEAK_HOLDER = proc do
        RMExtensions::WeakHolder.new
      end

      # creates an +attr_accessor+ like behavior, but the object is
      # stored within an NSHashTable.weakObjectsHashTable and retrieved
      # from the NSHashTable on demand.
      # does not conform to KVO like a normal attr_accessor.
      def rmext_weak_attr_accessor(*attrs)
        attrs.each do |attr|
          attr_holder = "#{attr}_holder"
          define_method(attr) do
            if holder = rmext_ivar(attr_holder)
              holder.value
            end
          end
          define_method("#{attr}=") do |val|
            holder = rmext_ivar(attr_holder, &CREATE_WEAK_HOLDER)
            holder.value = val
            val
          end
        end
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Accessors)
