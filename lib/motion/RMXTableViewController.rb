class RMXTableViewController < UITableViewController

  include RMXCommonMethods
  include RMXViewControllerPresentation
  include RMXKeyboardHelpers
  include RMXSetAttributes

  def init
    s = super
    RMX.log_dealloc(self)
    viewStateSignal
    listenForKeyboardChanged
    prepare
    s
  end

  def prepare
  end

  def loaded
  end

  def viewDidLoad
    s = super
    loaded
    s
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end
  
end
