class Proc

  def rmx_weak!(fallback_return=nil, desc=nil)
    block = RMX.safe_block(fallback_return, desc, &self)
    RMX.block_to_lambda_if_possible(arity, &block)
  end

  def rmx_unsafe!
    RMX.block_to_lambda_if_possible(arity, &weak!)
  end

  def rmx_strong!
    RMX.block_to_lambda_if_possible(arity, &self)
  end

end

class RMX

  def self.safe_block(fallback_return=nil, desc=nil, &block)
    weak_block_owner_holder = RMXWeakHolder.new(block.owner)
    block.weak!
    proc do |*args|
      if wbo = weak_block_owner_holder.value
        block.call(*args)
      else
        NSLog("PREVENTED BLOCK (#{[ desc, weak_block_owner_holder.inspect ].compact.join(", ")}).  Something is holding onto this block longer than it should, and probably leaking.")
        fallback_return
      end
    end
  end

  def self.safe_lambda(fallback_return=nil, desc=nil, &block)
    x = safe_block(fallback_return, desc, &block)
    block_to_lambda(block.arity, &x)
  end

  def self.block_to_lambda_if_possible(arity=nil, &block)
    arity ||= block.arity
    if block.lambda?
      block
    elsif arity > -1
      block_to_lambda(arity, &block)
    else
      block
    end
  end

  def self.block_to_lambda(arity=nil, &block)
    arity ||= block.arity
    case arity
    when 0
      -> { block.call }
    when 1
      ->(a) { block.call(a) }
    when 2
      ->(a,b) { block.call(a,b) }
    when 3
      ->(a,b,c) { block.call(a,b,c) }
    when 4
      ->(a,b,c,d) { block.call(a,b,c,d) }
    when 5
      ->(a,b,c,d,e) { block.call(a,b,c,d,e) }
    when 6
      ->(a,b,c,d,e,f) { block.call(a,b,c,d,e,f) }
    when 7
      ->(a,b,c,d,e,f,g) { block.call(a,b,c,d,e,f,g) }
    when 8
      ->(a,b,c,d,e,f,g,h) { block.call(a,b,c,d,e,f,g,h) }
    when 9
      ->(a,b,c,d,e,f,g,h,i) { block.call(a,b,c,d,e,f,g,h,i) }
    when 10
      ->(a,b,c,d,e,f,g,h,i,j) { block.call(a,b,c,d,e,f,g,h,i,j) }
    else
      raise "RMX.block_to_lambda unsupported arity #{block.arity}"
    end.weak!
  end

end
