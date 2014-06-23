class RMXTableViewCellInnerContentView < RMXView
  RMX.new(self).weak_attr_accessor :cell
  attr_accessor :autoUpdateHeight

  def layoutSubviews
    s = super
    updateHeight! if @autoUpdateHeight
    s
  end

  def updateHeight!
    if c = cell
      c.updateHeight!
    end
  end
end
