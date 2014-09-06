class RMXNavigationController < UINavigationController

  include RMXCommonMethods
  include RMXViewControllerPresentation

  RMX.new(self).weak_attr_accessor :lastShownViewController

  def animating?
    if vc = viewControllers.last
      vc != lastShownViewController
    end
  end

  def navigationController(navigationController, didShowViewController:view_controller, animated:animated)
    self.lastShownViewController = view_controller
    Dispatch::Queue.main.async do
      unless animating?
        navigationBar.userInteractionEnabled = true
        RMX.new(self).trigger(:done_animating)
      end
    end
  end

  def pushViewController(view_controller, animated:animated)
    unless animating?
      super
    else
      navigationBar.userInteractionEnabled = false
      p "DELAYED pushViewController:animated:", view_controller, animated
      RMX.new(self).once(:done_animating) do
        p "RESUMED pushViewController:animated:", view_controller, animated
        pushViewController(view_controller, animated:animated)
      end
      nil
    end
  end

  def popViewControllerAnimated(animated)
    unless animating?
      super
    else
      navigationBar.userInteractionEnabled = false
      p "DELAYED popViewControllerAnimated:", animated
      RMX.new(self).once(:done_animating) do
        p "RESUMED popViewControllerAnimated:", animated
        popViewControllerAnimated(animated)
      end
      nil
    end
  end

  def popToRootViewControllerAnimated(animated)
    unless animating?
      super
    else
      navigationBar.userInteractionEnabled = false
      p "DELAYED popToRootViewControllerAnimated:", animated
      RMX.new(self).once(:done_animating) do
        p "RESUMED popToRootViewControllerAnimated:", animated
        popToRootViewControllerAnimated(animated)
      end
      nil
    end
  end
  def popToViewController(view_controller, animated:animated)
    unless animating?
      super
    else
      navigationBar.userInteractionEnabled = false
      p "DELAYED popToViewController:animated:", view_controller, animated
      RMX.new(self).once(:done_animating) do
        p "RESUMED popToViewController:animated:", view_controller, animated
        popToViewController(view_controller, animated:animated)
      end
      nil
    end
  end

  def viewDidLoad
    s = super
    s
  end

  def viewWillAppear(animated)
    s = super
    rmx_viewWillAppear(animated)
    s
  end

  def viewDidAppear(animated)
    s = super
    rmx_viewDidAppear(animated)
    s
  end

  def viewWillDisappear(animated)
    s = super
    resignApplicationFirstResponder
    rmx_viewWillDisappear(animated)
    s
  end

  def viewDidDisappear(animated)
    s = super
    rmx_viewDidDisappear(animated)
    s
  end

  def resignApplicationFirstResponder
    windows = [] + UIApplication.sharedApplication.windows
    while window = windows.pop
      window.endEditing(true)
    end
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end

  def self.create(rootViewController)
    v = alloc.initWithNavigationBarClass(UINavigationBar, toolbarClass:nil)
    v.delegate = v
    v.pushViewController(rootViewController, animated: false) if rootViewController
    v
  end
  
end
