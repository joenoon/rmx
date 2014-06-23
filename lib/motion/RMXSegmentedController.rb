class RMXSegmentedController < RMXViewController

  def prepare
    @controller_indexes = []
    @control = UISegmentedControl.new
    @control.addTarget(self, action:'control_change:', forControlEvents:UIControlEventValueChanged)
  end

  def loaded
    navigationItem.titleView = @control
    self.selectedIndex = 0
  end

  def segments=(segments)
    @controller_indexes.clear
    @control.removeAllSegments
    if segments
      segments.each_with_index do |segment, i|
        if segment[:title]
          @control.insertSegmentWithTitle(segment[:title], atIndex:i, animated:false)
        elsif segment[:image]
          @control.insertSegmentWithImage(segment[:image], atIndex:i, animated:false)
        end
        @controller_indexes[i] = segment[:controller]
      end
    end
    @control.sizeToFit
  end

  def control_change(sender)
    self.selectedIndex = sender.selectedSegmentIndex
  end

  def selectedIndex=(i)
    cleanup_active
    @control.selectedSegmentIndex = @control.numberOfSegments > i ? i : UISegmentedControlNoSegment
    @active_controller = @controller_indexes[i]
    if @active_controller
      addChildViewController(@active_controller)
      RMExtensions::Layout.new do |layout|
        layout.view = view
        layout.subviews = {
          "content" => @active_controller.view
        }
        layout.eqs %Q{
          content.left == 0
          content.right == 0
          content.top == 0
          content.bottom == 0
        }
      end
      @active_controller.didMoveToParentViewController(self)
    end
  end

  def cleanup_active
    if @active_controller
      @active_controller.willMoveToParentViewController(nil)
      @active_controller.view.removeFromSuperview
      @active_controller.removeFromParentViewController
      @active_controller = nil
    end
  end

  def rmx_dealloc
    cleanup_active
    @controller_indexes = nil
  end

end

