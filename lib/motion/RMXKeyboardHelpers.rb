module RMXKeyboardHelpers

  def keyboard_proxy
    keyboard_proxy_constraints unless @keyboard_proxy_constraints
    @keyboard_proxy
  end

  def keyboard_proxy_constraints
    @keyboard_proxy ||= UIView.new
    @keyboard_proxy_constraints ||= begin
      x = {}
      RMExtensions::Layout.new do |layout|
        layout.view = view
        layout.subviews = {
          "keyboard_proxy" => @keyboard_proxy
        }
        x[:bottom] = layout.eq "keyboard_proxy.bottom == #{-RMX.currentKeyboardHeight}"
        x[:height] = layout.eq "keyboard_proxy.height == 0"
      end
      x
    end
  end

  def listenForKeyboardChanged
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'keyboardChangedInternal:', name:"rmxKeyboardChanged", object:nil)
  end

  # listens for the rmxKeyboardChanged notification and extracts the userInfo to call a friendlier method
  def keyboardChangedInternal(notification)
    if isViewLoaded
      info = notification.userInfo
      keyboardChanged(info)
    end
  end

  # by default, looks to see if the controller is using the @keyboard_proxy_constraint convention.
  # if so, sets the constraint's constant and refreshes the layout in the same animationDuration
  # as the keyboard's animation.
  #
  # if you want to do more/other stuff on keyboardChanged, you can override this, call super, or
  # do everything on your own.
  def keyboardChanged(info)
    if constraint = @keyboard_proxy_constraints && @keyboard_proxy_constraints[:height]
      Dispatch::Queue.main.async do
        UIView.animateWithDuration(info[:animationDuration], animations: lambda do
          keyboard_proxy_constraints[:bottom].constant = -RMX.currentKeyboardHeight
          view.setNeedsUpdateConstraints
          view.layoutIfNeeded
        end)
      end
    end
  end

end
