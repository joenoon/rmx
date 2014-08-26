class RMXViewController < UIViewController

  include RMXCommonMethods
  include RMXViewControllerPresentation
  include RMXKeyboardHelpers
  include RMXSetAttributes
  include RMXHideTableViewHeader

  def init
    s = super
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'refresh', name:UIApplicationWillEnterForegroundNotification, object:nil)
    listenForKeyboardChanged
    prepare
    s
  end

  def prepare
  end

  def loaded
  end

  def refresh
  end

  def viewDidLoad
    s = super
    loaded
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
    rmx_viewWillDisappear(animated)
    s
  end

  def viewDidDisappear(animated)
    s = super
    rmx_viewDidDisappear(animated)
    s
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end

  def dealloc
    NSNotificationCenter.defaultCenter.removeObserver(self)
    super
  end

end
