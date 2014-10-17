class UIView

  # creates a signal that will add the gesture to the view, `next` the gesture
  # when it executes, and remove the gesture when disposed (which should be
  # automatic if you make sure not to use strong blocks in subscribeNext).
  #
  def rmx_gestureSignal(gesture, enableInteraction=true)
    setUserInteractionEnabled(true) if enableInteraction
    RACSignal.createSignal(->(subscriber) {
      addGestureRecognizer(gesture)
      gesture.rac_gestureSignal.takeUntil(rac_willDeallocSignal).subscribe(subscriber)
      RACDisposable.disposableWithBlock(-> {
        removeGestureRecognizer(gesture)
      }.weak!)
    }.weak!).subscribeOn(RACScheduler.mainThreadScheduler)
  end

  def rmx_tapSignal(enableInteraction=true)
    rmx_gestureSignal(UITapGestureRecognizer.new, enableInteraction)
  end

  def rmx_pinchSignal(enableInteraction=true)
    rmx_gestureSignal(UIPinchGestureRecognizer.new, enableInteraction)
  end

  def rmx_rotationSignal(enableInteraction=true)
    rmx_gestureSignal(UIRotationGestureRecognizer.new, enableInteraction)
  end

  def rmx_swipeSignal(enableInteraction=true)
    rmx_gestureSignal(UISwipeGestureRecognizer.new, enableInteraction)
  end

  def rmx_panSignal(enableInteraction=true)
    rmx_gestureSignal(UIPanGestureRecognizer.new, enableInteraction)
  end

  def rmx_screenEdgePanSignal(enableInteraction=true)
    rmx_gestureSignal(UIScreenEdgePanGestureRecognizer.new, enableInteraction)
  end

  def rmx_longPressSignal(enableInteraction=true)
    rmx_gestureSignal(UILongPressGestureRecognizer.new, enableInteraction)
  end

end
