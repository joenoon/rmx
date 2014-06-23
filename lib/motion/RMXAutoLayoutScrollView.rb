class RMXAutoLayoutScrollView < UIScrollView
  class FollowView < UIView
    RMX.new(self).weak_attr_accessor :fittedView
    def layoutSubviews
      s = super
      fittedView.invalidateIntrinsicContentSize
      fittedView.setNeedsUpdateConstraints
      fittedView.layoutIfNeeded
      s
    end
  end
  class FittedView < UIView
    RMX.new(self).weak_attr_accessor :followView
    def intrinsicContentSize
      followView.frame.size
    end
  end
  attr_accessor :contentView
  def self.fitted_to(parent)
    followView = FollowView.new
    followView.userInteractionEnabled = false
    followView.hidden = true
    fittedView = FittedView.new
    fittedView.backgroundColor = UIColor.clearColor
    fittedView.followView = followView
    followView.fittedView = fittedView
    # add a subview to parent called followView
    RMX::Layout.new do |layout|
      layout.view parent
      layout.subviews "x" => followView
      layout.eqs %Q{
        x.top == 0
        x.right == 0
        x.bottom == 0
        x.left == 0
      }
    end
    x = new
    x.contentView = fittedView
    # add a subview to scrollView called contentView
    RMX::Layout.new do |layout|
      layout.view x
      layout.subviews "x" => fittedView
      layout.eqs %Q{
        x.top == 0
        x.right == 0
        x.bottom == 0
        x.left == 0
      }
    end
    x
  end
end
