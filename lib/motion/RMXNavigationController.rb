class RMXNavigationController < UINavigationController

  include RMXCommonMethods
  include RMXViewControllerPresentation

  attr_accessor :transitionSignal, :transitionSubject, :transitioning, :rootViewControllerOnLoad

  def navigationController(navigationController, willShowViewController:view_controller, animated:animated)
    @transitioning = true
    navigationController.transitionSubject.sendNext(true)
  end

  def navigationController(navigationController, didShowViewController:view_controller, animated:animated)
    @transitioning = false
    @queued_ops.each do |item|
      send(*item)
    end
    @queued_ops.clear
    navigationController.transitionSubject.sendNext(false)
  end

  def pushViewController(view_controller, animated:animated)
    if !@transitioning
      super
    else
      @queued_ops << [ 'pushViewController:animated:', view_controller, false ]
    end
    nil
  end

  def popViewControllerAnimated(animated)
    if !@transitioning
      super
    else
      @queued_ops << [ 'popViewControllerAnimated:', false ]
    end
    nil
  end

  def popToRootViewControllerAnimated(animated)
    if !@transitioning
      super
    else
      @queued_ops << [ 'popToRootViewControllerAnimated:', false ]
    end
    nil
  end

  def popToViewController(view_controller, animated:animated)
    if !@transitioning
      if viewControllers.include?(view_controller)
        super
      end
    else
      @queued_ops << [ 'popToViewController:animated:', view_controller, false ]
    end
    nil
  end

  def setViewControllers(controllers, animated:animated)
    if !@transitioning
      super
    else
      @queued_ops << [ 'setViewControllers:animated:', controllers, false ]
    end
    nil
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end

  def viewDidLoad
    RMX.log_dealloc(self)
    @queued_ops = []
    @transitionSubject = RACReplaySubject.replaySubjectWithCapacity(1)
    @transitionSignal = @transitionSubject.subscribeOn(RACScheduler.mainThreadScheduler)

    viewStateSignal

    rac_signalForSelector('viewDidDisappear:').subscribeNext(->(tuple) { RMX.resignApplicationFirstResponder }.rmx_unsafe!)

    self.delegate = self

    pushViewController(rootViewControllerOnLoad, animated: false) if rootViewControllerOnLoad

    self.rootViewControllerOnLoad = nil

  end

  def self.create(rootViewController)
    v = alloc.initWithNavigationBarClass(UINavigationBar, toolbarClass:nil)
    v.rootViewControllerOnLoad = rootViewController
    v
  end
  
end
