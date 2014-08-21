class RMXTableHandlerViewCell < RMXTableViewCell

  RMX.new(self).weak_attr_accessor :tableView
  RMX.new(self).weak_attr_accessor :tableHandler
  attr_accessor :indexPath, :sizerCellReuseIdentifier

  def setNeedsUpdateConstraints
    super unless sizerCellReuseIdentifier
  end
  def setNeedsLayout
    super unless sizerCellReuseIdentifier
  end
  def setNeedsDisplay
    super unless sizerCellReuseIdentifier
  end
  def setNeedsDisplayInRect(rect)
    super unless sizerCellReuseIdentifier
  end
  def layoutIfNeeded
    super unless sizerCellReuseIdentifier
  end

  def context=(context)
    self.tableHandler = context[:tableHandler]
    self.tableView = context[:tableView]
    self.indexPath = context[:indexPath]
    self.data = context[:data]
    self.view = context[:view]
    if context[:transform] && transform != context[:transform]
      self.transform = context[:transform]
    end
  end

  def data
    @data
  end

  def data=(data)
    @data = data
  end

  def view
    @view
  end

  def view=(view)
    @view.removeFromSuperview if @view
    if @view = view
      RMX::Layout.new do |layout|
        layout.view = innerContentView
        layout.subviews = {
          "tile" => view
        }
        layout.eqs %Q{
          tile.top == 0
          tile.left == 0
          tile.right == 0
          tile.bottom == 0 @ 500
        }
      end
    end
    view
  end

end
