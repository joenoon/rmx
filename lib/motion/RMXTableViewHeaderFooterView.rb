class RMXTableViewHeaderFooterView < UITableViewHeaderFooterView

  include RMXCommonMethods

  attr_reader :innerContentView

  def initWithReuseIdentifier(reuseIdentifier)
    s = super
    setup
    s
  end

  def setup
  end

  def useAutoLayout!
    @innerContentView = RMXView.new
    RMX::Layout.new do |layout|
      layout.view = contentView
      layout.eqs %Q{
        innerContentView.top == 0
        innerContentView.left == 0
        innerContentView.right == 0 @ med
        innerContentView.bottom == 0 @ med
      }
    end
    self
  end

  def layoutSubviews
    s = super
    if @innerContentView
      height = @innerContentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 10
      _frame = frame
      if _frame.size.height != height
        _frame.size.height = height
        _frame.size.width = 1000
        self.frame = _frame
      end
    end
    s
  end

end
