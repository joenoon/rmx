class RMX

  CREATE_WEAK_HOLDER = proc do
    RMXWeakHolder.new
  end

  # creates an +attr_accessor+ like behavior, but the object is
  # stored within an NSHashTable.weakObjectsHashTable and retrieved
  # from the NSHashTable on demand.
  # does not conform to KVO like a normal attr_accessor.
  def weak_attr_accessor(*attrs)
    if object = unsafe_unretained_object
      attrs.each do |attr|
        attr_holder = "#{attr}_holder"
        object.send(:define_method, attr) do
          if holder = RMX.new(self).ivar(attr_holder)
            holder.value
          end
        end
        object.send(:define_method, "#{attr}=") do |val|
          holder = RMX.new(self).ivar(attr_holder, &CREATE_WEAK_HOLDER)
          holder.value = val
          val
        end
      end
    end
  end

end
