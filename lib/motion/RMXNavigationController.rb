class RMXNavigationController < UINavigationController

  include RMXCommonMethods
  include RMXViewControllerPresentation

  def rmx_init
    RMX.log_dealloc(self)
    viewStateSignal
    self.delegate = self
    nil
  end

  def initWithNibName(name, bundle:bundle)
    s = super
    rmx_init
    s
  end

  def initWithCoder(decoder)
    s = super
    rmx_init
    s
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end

  def self.create(rootViewController)
    alloc.initWithRootViewController(rootViewController)
  end
  
end
