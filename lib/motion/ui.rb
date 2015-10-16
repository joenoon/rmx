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

  def self.resignApplicationFirstResponder
    windows = [] + UIApplication.sharedApplication.windows
    while window = windows.pop
      window.endEditing(true)
    end
    nil
  end

  def self.currentKeyboardHeight
    @currentKeyboardHeight || 0
  end

  RMX.rac_keyboardWillHideNotification
  .subscribeNext(->(notification) {
    info = notification.userInfo
    animationDuration = info.objectForKey(UIKeyboardAnimationDurationUserInfoKey)
    @currentKeyboardHeight = 0
    NSNotificationCenter.defaultCenter.postNotificationName("rmxKeyboardChanged", object:nil, userInfo:{
      :height => 0,
      :animationDuration => animationDuration
    })
  })

  RMX.rac_keyboardWillShowNotification
  .subscribeNext(->(notification) {
    info = notification.userInfo
    keyboardFrame = info.objectForKey(UIKeyboardFrameEndUserInfoKey).CGRectValue
    animationDuration = info.objectForKey(UIKeyboardAnimationDurationUserInfoKey)
    currentKeyboardHeight = keyboardFrame.size.height
    @currentKeyboardHeight = currentKeyboardHeight
    NSNotificationCenter.defaultCenter.postNotificationName("rmxKeyboardChanged", object:nil, userInfo:{
      :height => currentKeyboardHeight,
      :animationDuration => animationDuration
    })
  })

end
