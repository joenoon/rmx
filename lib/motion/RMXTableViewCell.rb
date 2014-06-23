class RMXTableViewCell < UITableViewCell

  include RMXCommonMethods

  RMX.new(self).weak_attr_accessor :tableView
  RMX.new(self).weak_attr_accessor :tableHandler
  attr_accessor :indexPath, :innerContentView

  def initWithStyle(style, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    s = super(style, reuseIdentifier)
    @innerContentView = RMXTableViewCellInnerContentView.new
    @innerContentView.cell = self
    RMExtensions::Layout.new do |layout|
      layout.view = contentView
      layout.subviews = {
        "innerContentView" => @innerContentView
      }
      layout.eqs %Q{
        innerContentView.top == 0
        innerContentView.left == 0
        innerContentView.right == 0
        innerContentView.bottom == 0 @ med
      }
    end
    setup
    s
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

  def setup
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
      RMExtensions::Layout.new do |layout|
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

  def updateHeight!
    if (d = data) && (h = tableHandler)
      height = contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
      # p "height", height
      if h.updateHeight(height, data:d, reuseIdentifier:reuseIdentifier)
        h.reloadData
      end
    end
  end

end
