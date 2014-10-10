class RMX

  # Shortcut to instance_variable_get and instance_variable_get:
  # 1 arg for instance_variable_get
  # 1 arg and block for instance_variable_get || instance_variable_set
  # 2 args for instance_variable_set
  def ivar(*args, &block)
    if object = unsafe_unretained_object
      key = args[0]
      val = nil
      if args.size == 1
        if block
          val = object.instance_variable_get("@#{key}")
          if val.nil?
            val = block.call
            object.instance_variable_set("@#{key}", val)
            val
          end
        else
          val = object.instance_variable_get("@#{key}")
        end
      elsif args.size == 2
        val = args[1]
        object.instance_variable_set("@#{key}", val)
      else
        raise "RMX#ivar called with invalid arguments: #{args.inspect}"
      end
      val
    end
  end

end
