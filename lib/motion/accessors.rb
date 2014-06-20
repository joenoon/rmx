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

      CREATE_WEAK_TABLE = proc do
        NSHashTable.weakObjectsHashTable
      end

      # creates an +attr_accessor+ like behavior, but the object is
      # stored within an NSHashTable.weakObjectsHashTable and retrieved
      # from the NSHashTable on demand.
      # does not conform to KVO like a normal attr_accessor.
      def rmext_weak_attr_accessor(*attrs)
        attrs.each do |attr|
          attr_holder = "#{attr}_holder"
          define_method(attr) do
            next if _isDeallocating
            autorelease_pool do
              next if _isDeallocating
              if holder = rmext_ivar(attr_holder)
                autorelease_pool do
                  next if _isDeallocating
                  out = if ref = holder.anyObject
                    if ref._isDeallocating
                      nil
                    else
                      ref
                    end
                  end
                  out
                end
              end
            end
          end
          define_method("#{attr}=") do |val|
            holder = rmext_ivar(attr_holder, &CREATE_WEAK_TABLE)
            holder.removeAllObjects
            holder.addObject(val)
            val
          end
        end
      end

    end

  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Accessors)
