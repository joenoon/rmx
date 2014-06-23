class RMX

  def self.app
    UIApplication.sharedApplication
  end

  def self.ios_version
    @ios_version ||= UIDevice.currentDevice.systemVersion.split(".").take(2).join(".").to_f    
  end

  def self.screen_pixel
    1.0 / UIScreen.mainScreen.scale
  end

  def self.keyboardWillChangeFrame(notification)
    @keyboardWillChangeFrameNotification = notification
    processKeyboardWillChange
  end

  def self.processKeyboardWillChange
    return unless notification = @keyboardWillChangeFrameNotification
    info = notification.userInfo
    keyboardFrame = info.objectForKey(UIKeyboardFrameEndUserInfoKey).CGRectValue
    bounds = UIScreen.mainScreen.bounds
    animationDuration = info.objectForKey(UIKeyboardAnimationDurationUserInfoKey).doubleValue
    #  below the screen                              # above the screen                                                       # left of the screen                                                    # right of the screen
    currentKeyboardHeight = if keyboardFrame.origin.y >= bounds.size.height || keyboardFrame.origin.y <= bounds.origin.y - keyboardFrame.size.height || keyboardFrame.origin.x <= bounds.origin.x - keyboardFrame.size.width || keyboardFrame.origin.x >= bounds.size.width
      0
    else
      keyboardFrame.size.height
    end
    # p "================>"
    if currentKeyboardHeight != @currentKeyboardHeight
      @currentKeyboardHeight = currentKeyboardHeight
      # p "currentKeyboardHeight", currentKeyboardHeight
      # p "keyboardFrame", keyboardFrame
      # p "UIScreen.mainScreen.bounds", UIScreen.mainScreen.bounds
      NSNotificationCenter.defaultCenter.postNotificationName("rmxKeyboardChanged", object:nil, userInfo:{
        :height => currentKeyboardHeight,
        :animationDuration => animationDuration
      })
    end
    @keyboardWillChangeFrameNotification = nil
  end

  def self.currentKeyboardHeight
    @currentKeyboardHeight || 0
  end
  NSNotificationCenter.defaultCenter.addObserver(self, selector:'keyboardWillChangeFrame:', name:UIKeyboardWillChangeFrameNotification, object:nil)

end

def RMX(_object)
  RMX.new(_object)
end
