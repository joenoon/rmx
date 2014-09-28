class RMXView < UIView

  include RMXCommonMethods
  include RMXSetAttributes

  def prepare
  end

  def setup
  end

  def init
    s = super
    if RMX::IOS8_COMPAT
      self.layoutMargins = UIEdgeInsetsZero
    end
    prepare
    setUserInteractionEnabled(false)
    setup
    s
  end

  def setUserInteractionEnabled(bool)
    @userInteractionEnabled = bool
  end

  def self.create(attributes={})
    x = new
    x.attributes = attributes
    x
  end

  # normal userInteractionEnabled means the view and all subviews can't be clicked.  what we normally
  # want is subviews to be clickable, but not the parent.  this custom hitTest allows that behavior.
  def hitTest(point, withEvent:event)
    s = super
    if s == self && @userInteractionEnabled == false
      return nil
    end
    s
  end

  def self.requiresConstraintBasedLayout
    true
  end

end
