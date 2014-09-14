class RMXTableViewController < UITableViewController

  include RMXCommonMethods
  include RMXViewControllerPresentation
  include RMXKeyboardHelpers
  include RMXSetAttributes
  include RMXHideTableViewHeader

  def prepare
  end

  def loaded
  end

  def init
    s = super
    listenForKeyboardChanged
    prepare
    s
  end

  def viewDidLoad
    s = super
    viewStateSignal
    loaded
    s
  end

  def didReceiveMemoryWarning
    p "didReceiveMemoryWarning"
    super
  end
  
end
