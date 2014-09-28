class UIResponder

  Dispatch.once do
    $rmx_currentFirstResponder = RMXWeakHolder.new
  end
 
  def self.rmx_currentFirstResponder
    $rmx_currentFirstResponder.value = nil
    UIApplication.sharedApplication.sendAction('rmx_findFirstResponder:', to:nil, from:nil, forEvent:nil)
    $rmx_currentFirstResponder.value
  end

  def self.rmx_findFirstResponder(sender)
    $rmx_currentFirstResponder.value = sender
  end

end
