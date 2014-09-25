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
