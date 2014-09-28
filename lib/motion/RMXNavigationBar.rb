# The navigtionBar seems to steal taps from views about 6-10px below it, for example
# a button in the first UITableViewCell of a table could become half-tappable. There
# must be a simpler solution to this, but until then, this seems to fix it so far.
#
# Adapted from https://gist.github.com/nonamelive/8287674ea7cfc1a9d2ff
class RMXNavigationBar < UINavigationBar

  attr_accessor :shouldOnlyReceiveTouchEventsInsideNavigationBar
  attr_accessor :changingUserInteraction
  attr_accessor :userInteractionChangedBySystem

  def isFirstResponderADescendantView
    if firstResponder = UIResponder.rmx_currentFirstResponder
      firstResponder.is_a?(UIView) && firstResponder.isDescendantOfView(self)
    end
  end

  def hitTest(point, withEvent:event)
    if shouldOnlyReceiveTouchEventsInsideNavigationBar
      if userInteractionChangedBySystem && userInteractionEnabled? == false
        # p "hitTest return super"
        return super
      end

      if pointInside(point, withEvent:event) || isFirstResponderADescendantView
        # p "point is inside"
        self.changingUserInteraction = true
        self.userInteractionEnabled = true
        self.changingUserInteraction = false
      else
        # p "point is outside"
        self.changingUserInteraction = true
        self.userInteractionEnabled = false
        self.changingUserInteraction = false
      end
    end
    super
  end

  def setUserInteractionEnabled(userInteractionEnabled)
    if shouldOnlyReceiveTouchEventsInsideNavigationBar
      if !self.changingUserInteraction
        # p "setUserInteractionEnabled", userInteractionEnabled, "userInteractionChangedBySystem", true
        self.userInteractionChangedBySystem = true
      else
        # p "setUserInteractionEnabled", userInteractionEnabled, "userInteractionChangedBySystem", false
        self.userInteractionChangedBySystem = false
      end
    end
    super
  end
end
