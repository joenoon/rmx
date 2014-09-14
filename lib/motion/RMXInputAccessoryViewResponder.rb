class RMXInputAccessoryViewResponder < UIView
  
  attr_accessor :inputAccessoryView

  def init
    s = super
    self.frame = CGRectMake(-1, -1, 0, 0)
    self.userInteractionEnabled = false
    s
  end

  def inputAccessoryView
    @inputAccessoryView
  end

  def canBecomeFirstResponder
    !!@inputAccessoryView
  end

  def canResignFirstResponder
    true
  end

end

