class RMXView < UIView

  include RMXCommonMethods
  include RMXSetAttributes

  attr_accessor :updatedSize, :reportSizeChanges

  def dealloc
    NSNotificationCenter.defaultCenter.removeObserver(self)
    super
  end

  def prepare
  end

  def setup
  end

  def init
    s = super
    prepare
    setUserInteractionEnabled(false)
    setup
    s
  end

  def setUserInteractionEnabled(bool)
    @userInteractionEnabled = bool
  end

  def self.create(attributes={})
    x = new
    x.attributes = attributes
    x
  end

  # normal userInteractionEnabled means the view and all subviews can't be clicked.  what we normally
  # want is subviews to be clickable, but not the parent.  this custom hitTest allows that behavior.
  def hitTest(point, withEvent:event)
    s = super
    if s == self && @userInteractionEnabled == false
      return nil
    end
    s
  end

  def requiresConstraintBasedLayout
    true
  end

  def layoutSubviews
    s = super
    if reportSizeChanges
      Dispatch::Queue.main.async do
        size = systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        unless updatedSize == size
          self.updatedSize = size
          RMX.new(self).trigger(:updatedSize, size)
          
          if tableView = is_or_within_a?(UITableView)
            if tableView.delegate.respondsToSelector('tableView:viewDidUpdateSize:')
              tableView.delegate.tableView(tableView, viewDidUpdateSize:self)
            end
            # p "unbounced reload"
            RMX.new(self).debounce(:reloadTableUpdatedSize) do
              # p "debounced reload"
              if controller = tableView.lAncestorViewController
                if controller.viewState == :viewDidAppear
                  tableView.beginUpdates
                  tableView.endUpdates
                else
                  tableView.reloadData
                end
              end
            end
          end

        end
      end
    end
    s
  end

end
