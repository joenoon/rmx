class RMXTableViewCell < UITableViewCell

  include RMXCommonMethods

  attr_accessor :innerContentView

  def initWithStyle(style, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    s = super(style, reuseIdentifier)
    if RMX::IOS8_COMPAT
      self.layoutMargins = UIEdgeInsetsZero
    end
    @innerContentView = RMXView.new
    RMX::Layout.new do |layout|
      layout.view = contentView
      layout.subviews = {
        "innerContentView" => @innerContentView
      }
      layout.eqs %Q{
        innerContentView.top == 0
        innerContentView.left == 0
        innerContentView.right == 0
        innerContentView.bottom == 0 @ 999
      }
    end
    setup
    s
  end

  def prepareForReuse
    reset
  end

  def reset
  end

  def setup
  end

end
