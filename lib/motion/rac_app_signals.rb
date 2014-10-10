RMXApplicationDidBecomeActiveFromBackground = "RMXApplicationDidBecomeActiveFromBackground"
RMXApplicationDidBecomeActiveFromForeground = "RMXApplicationDidBecomeActiveFromForeground"

class RMX

  # App Flow notes:
  #
  # Launch:
  # 1.) UIApplicationDidFinishLaunchingNotification
  # 2.) UIApplicationDidBecomeActiveNotification
  #
  # Post-Launch at some point:
  # 3.) UIApplicationWillResignActiveNotification
  #
  # Conditionally, if its really going to the background vs temporarily inactive:
  # 4.) UIApplicationDidEnterBackgroundNotification
  # 5.) UIApplicationWillEnterForegroundNotification
  #
  # And eventually, back to active:
  # 6.) UIApplicationDidBecomeActiveNotification
  #
  # This chart is also useful: http://www.cocoanetics.com/files/UIApplication_Delegate_post_4_v121.jpg
  #

  # Custom RMX signal
  # Signals UIApplicationDidBecomeActiveNotification only after UIApplicationDidEnterBackgroundNotification has signaled
  def self.rac_appDidBecomeActiveFromBackground
    rac_appSignal(RMXApplicationDidBecomeActiveFromBackground)
  end

  # Custom RMX signal
  # Signals UIApplicationDidBecomeActiveNotification unless UIApplicationDidEnterBackgroundNotification signaled
  def self.rac_appDidBecomeActiveFromForeground
    rac_appSignal(RMXApplicationDidBecomeActiveFromForeground)
  end

  # Posted immediately after the app finishes launching.
  # If the app was launched as a result of in remote notification targeted at it or because another app opened a URL
  # resource claimed the posting app (the notification object), this notification contains a userInfo dictionary.
  # You can access the contents of the dictionary using the UIApplicationLaunchOptionsURLKey and
  # UIApplicationLaunchOptionsSourceApplicationKey constants (for URLs), the
  # UIApplicationLaunchOptionsRemoteNotificationKey constant (for remote notifications), and the
  # UIApplicationLaunchOptionsLocalNotificationKey constant (for local notifications). If the notification was
  # posted for a normal app launch, there is no userInfo dictionary.
  def self.rac_appDidFinishLaunchingNotification
    rac_appSignal(UIApplicationDidFinishLaunchingNotification)
  end

  # Posted when the app becomes active.
  # An app is active when it is receiving events. An active app can be said to have focus. It gains focus after being launched, loses focus when an overlay window pops up or when the device is locked, and gains focus when the device is unlocked.
  def self.rac_appDidBecomeActiveNotification
    rac_appSignal(UIApplicationDidBecomeActiveNotification)
  end

  # Posted when the app enters the background.
  # The object of the notification is the UIApplication object. There is no userInfo dictionary.
  def self.rac_appDidEnterBackgroundNotification
    rac_appSignal(UIApplicationDidEnterBackgroundNotification)
  end

  # Posted shortly before an app leaves the background state on its way to becoming the active app.
  # The object of the notification is the UIApplication object. There is no userInfo dictionary.
  def self.rac_appWillEnterForegroundNotification
    rac_appSignal(UIApplicationWillEnterForegroundNotification)
  end

  # Posted when the app is no longer active and loses focus.
  # An app is active when it is receiving events. An active app can be said to have focus. It gains focus after being launched, loses focus when an overlay window pops up or when the device is locked, and gains focus when the device is unlocked.
  def self.rac_appWillResignActiveNotification
    rac_appSignal(UIApplicationWillResignActiveNotification)
  end

  # Posted when the app is about to terminate.
  # This notification is associated with the delegate applicationWillTerminate: method. This notification does not contain a userInfo dictionary.
  def self.rac_appWillTerminateNotification
    rac_appSignal(UIApplicationWillTerminateNotification)
  end

  # Posted when the app’s status for downloading content in the background changes.
  # The system sends this notification when the backgroundRefreshStatus property of the app object changes. That property can change in response to the user disabling multitasking support for the app. The object of the notification is the UIApplication object. There is no userInfo dictionary.
  def self.rac_appBackgroundRefreshStatusDidChangeNotification
    rac_appSignal(UIApplicationBackgroundRefreshStatusDidChangeNotification)
  end

  # Posted when the frame of the status bar changes.
  # The userInfo dictionary contains an NSValue object that encapsulates a CGRect structure expressing the location and size of the new status bar frame. Use UIApplicationStatusBarFrameUserInfoKey to access this value.
  def self.rac_appDidChangeStatusBarFrameNotification
    rac_appSignal(UIApplicationDidChangeStatusBarFrameNotification)
  end

  # Posted when the orientation of the app’s user interface changes.
  # The userInfo dictionary contains an NSNumber object that encapsulates a UIInterfaceOrientation value (see UIInterfaceOrientation). Use UIApplicationStatusBarOrientationUserInfoKey to access this value
  def self.rac_appDidChangeStatusBarOrientationNotification
    rac_appSignal(UIApplicationDidChangeStatusBarOrientationNotification)
  end

  # Posted when the app receives a warning from the operating system about low memory availability.
  # This notification does not contain a userInfo dictionary.
  def self.rac_appDidReceiveMemoryWarningNotification
    rac_appSignal(UIApplicationDidReceiveMemoryWarningNotification)
  end

  # Posted when the protected files become available for your code to access.
  # This notification does not contain a userInfo dictionary.
  def self.rac_appProtectedDataDidBecomeAvailable
    rac_appSignal(UIApplicationProtectedDataDidBecomeAvailable)
  end

  # Posted shortly before protected files are locked down and become inaccessible.
  # Upon receiving this notification, clients should release any references to protected files. This notification does not contain a userInfo dictionary.
  def self.rac_appProtectedDataWillBecomeUnavailable
    rac_appSignal(UIApplicationProtectedDataWillBecomeUnavailable)
  end

  # Posted when there is a significant change in time, for example, change to a new day (midnight), carrier time update, and change to or from daylight savings time.
  # This notification does not contain a userInfo dictionary.
  def self.rac_appSignificantTimeChangeNotification
    rac_appSignal(UIApplicationSignificantTimeChangeNotification)
  end

  # Posted when the user presses the Home and Lock buttons to take a screenshot.
  # This notification does not contain a userInfo dictionary. This notification is posted after the screenshot is taken.
  def self.rac_appUserDidTakeScreenshotNotification
    rac_appSignal(UIApplicationUserDidTakeScreenshotNotification)
  end

  # Posted when the app is about to change the orientation of its interface.
  # The userInfo dictionary contains an NSNumber that encapsulates a UIInterfaceOrientation value (see UIInterfaceOrientation). Use UIApplicationStatusBarOrientationUserInfoKey to access this value.
  def self.rac_appWillChangeStatusBarOrientationNotification
    rac_appSignal(UIApplicationWillChangeStatusBarOrientationNotification)
  end

  # Posted when the app is about to change the frame of the status bar.
  # The userInfo dictionary contains an NSValue object that encapsulates a CGRect structure expressing the location and size of the new status bar frame. Use UIApplicationStatusBarFrameUserInfoKey to access this value.
  def self.rac_appWillChangeStatusBarFrameNotification
    rac_appSignal(UIApplicationWillChangeStatusBarFrameNotification)
  end

  # Posted when the user changes the preferred content size setting.
  # This notification is sent when the value in the preferredContentSizeCategory property changes. The userInfo dictionary of the notification contains the UIContentSizeCategoryNewValueKey key, which reflects the new setting.
  def self.rac_appContentSizeCategoryDidChangeNotification
    rac_appSignal(UIContentSizeCategoryDidChangeNotification)
  end


  # Posted when an UIWindow object becomes hidden.
  # The notification object is the window object that has become hidden. This notification does not contain a userInfo dictionary
  def self.rac_windowDidBecomeHiddenNotification
    rac_appSignal(UIWindowDidBecomeHiddenNotification)
  end

  # Posted whenever a UIWindow object becomes the key window.
  # The notification object is the window object that has become key. This notification does not contain a userInfo dictionary.
  def self.rac_windowDidBecomeKeyNotification
    rac_appSignal(UIWindowDidBecomeKeyNotification)
  end

  # Posted whenever a UIWindow object resigns its status as main window.
  # The notification object is the window object that has resigned its main window status. This notification does not contain a userInfo dictionary.
  def self.rac_windowDidResignKeyNotification
    rac_appSignal(UIWindowDidResignKeyNotification)
  end

  # Posted immediately prior to the display of the keyboard.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardWillShowNotification
    rac_appSignal(UIKeyboardWillShowNotification)
  end

  # Posted immediately after the display of the keyboard.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardDidShowNotification
    rac_appSignal(UIKeyboardDidShowNotification)
  end

  # Posted immediately prior to the dismissal of the keyboard.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardWillHideNotification
    rac_appSignal(UIKeyboardWillHideNotification)
  end

  # Posted immediately after the dismissal of the keyboard.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardDidHideNotification
    rac_appSignal(UIKeyboardDidHideNotification)
  end

  # Posted immediately prior to a change in the keyboard’s frame.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardWillChangeFrameNotification
    rac_appSignal(UIKeyboardWillChangeFrameNotification)
  end

  # Posted immediately after a change in the keyboard’s frame.
  # The notification object is nil. The userInfo dictionary contains information about the keyboard. Use the keys described in Keyboard Notification User Info Keys to get the location and size of the keyboard from the userInfo dictionary.
  def self.rac_keyboardDidChangeFrameNotification
    rac_appSignal(UIKeyboardDidChangeFrameNotification)
  end

  def self.launchedAt
    res = @launchedAt
    res
  end

  def self.lastResignedAt
    res = @lastResignedAt
    res
  end

  def self.lastActivatedAt
    res = @lastActivatedAt
    res
  end

  def self.secondsSinceLaunched
    if t = launchedAt
      Time.now - t
    else
      0
    end
  end

  def self.secondsSinceResigned
    if t = lastResignedAt
      Time.now - t
    else
      0
    end
  end

  def self.secondsSinceActivated
    if t = lastActivatedAt
      Time.now - t
    else
      0
    end
  end

  def self.rac_appSignal(name)
    res = @rmx_rac_appSignals[name].deliverOn(RACScheduler.mainThreadScheduler)
    res
  end

  Dispatch.once do

    @rmx_rac_appSignals = {}

    [
      UIApplicationDidFinishLaunchingNotification,
      UIApplicationDidBecomeActiveNotification,
      UIApplicationDidEnterBackgroundNotification,
      UIApplicationWillEnterForegroundNotification,
      UIApplicationWillResignActiveNotification,
      UIApplicationWillTerminateNotification,
      UIApplicationBackgroundRefreshStatusDidChangeNotification,
      UIApplicationDidChangeStatusBarFrameNotification,
      UIApplicationDidChangeStatusBarOrientationNotification,
      UIApplicationDidReceiveMemoryWarningNotification,
      UIApplicationProtectedDataDidBecomeAvailable,
      UIApplicationProtectedDataWillBecomeUnavailable,
      UIApplicationSignificantTimeChangeNotification,
      UIApplicationUserDidTakeScreenshotNotification,
      UIApplicationWillChangeStatusBarOrientationNotification,
      UIApplicationWillChangeStatusBarFrameNotification,
      UIContentSizeCategoryDidChangeNotification,

      UIWindowDidBecomeHiddenNotification,
      UIWindowDidBecomeKeyNotification,
      UIWindowDidResignKeyNotification,
      UIKeyboardWillShowNotification,
      UIKeyboardDidShowNotification,
      UIKeyboardWillHideNotification,
      UIKeyboardDidHideNotification,
      UIKeyboardWillChangeFrameNotification,
      UIKeyboardDidChangeFrameNotification
    ].each do |name|
      @rmx_rac_appSignals[name] = NSNotificationCenter.defaultCenter.rac_addObserverForName(name, object:nil)
    end

    @rmx_rac_appSignals[RMXApplicationDidBecomeActiveFromBackground] = RACSignal.createSignal(-> (subscriber) {
      sig = RACSubject.subject
      latest = sig.switchToLatest
      disposable = latest.subscribe(subscriber)

      rac_appSignal(UIApplicationDidEnterBackgroundNotification)
      .subscribeNext(->(v) {
        sig.sendNext(rac_appSignal(UIApplicationDidBecomeActiveNotification))
      })

      RACDisposable.disposableWithBlock(-> {
        disposable.dispose
      })
    })

    @rmx_rac_appSignals[RMXApplicationDidBecomeActiveFromForeground] = RACSignal.createSignal(-> (subscriber) {
      sig = RACSubject.subject
      latest = sig.switchToLatest
      disposable = latest.subscribe(subscriber)

      rac_appSignal(UIApplicationWillResignActiveNotification)
      .subscribeNext(->(v) {
        sig.sendNext(rac_appSignal(UIApplicationDidBecomeActiveNotification).takeUntil(rac_appSignal(UIApplicationDidEnterBackgroundNotification)))
      })

      RACDisposable.disposableWithBlock(-> {
        disposable.dispose
      })
    })

    rac_appSignal(UIApplicationDidFinishLaunchingNotification).subscribeNext(->(v) {
      if DEBUG_APP_STATE
        NSLog("*** UIApplicationDidFinishLaunchingNotification: #{v.description}")
      end
      @launchedAt = Time.now
    })

    rac_appSignal(UIApplicationDidBecomeActiveNotification).subscribeNext(->(v) {
      if DEBUG_APP_STATE
        NSLog("*** UIApplicationDidBecomeActiveNotification: #{v.description}")
      end
      @lastActivatedAt = Time.now
    })

    rac_appSignal(UIApplicationWillResignActiveNotification).subscribeNext(->(v) {
      if DEBUG_APP_STATE
        NSLog("*** UIApplicationWillResignActiveNotification: #{v.description}")
      end
      @lastResignedAt = Time.now
    })

    if DEBUG_APP_STATE
      rac_appSignal(UIApplicationDidEnterBackgroundNotification).subscribeNext(->(v) {
        NSLog("*** UIApplicationDidEnterBackgroundNotification: #{v.description}")
      })

      rac_appSignal(UIApplicationWillEnterForegroundNotification).subscribeNext(->(v) {
        NSLog("*** UIApplicationWillEnterForegroundNotification: #{v.description}")
      })

      rac_appSignal(UIApplicationWillTerminateNotification).subscribeNext(->(v) {
        NSLog("*** UIApplicationWillTerminateNotification: #{v.description}")
      })

      rac_appSignal(RMXApplicationDidBecomeActiveFromBackground).subscribeNext(->(v) {
        NSLog("*** RMXApplicationDidBecomeActiveFromBackground: #{v.description}")
      })

      rac_appSignal(RMXApplicationDidBecomeActiveFromForeground).subscribeNext(->(v) {
        NSLog("*** RMXApplicationDidBecomeActiveFromForeground: #{v.description}")
      })
    end

  end

end

