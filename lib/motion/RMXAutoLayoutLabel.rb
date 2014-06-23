class RMXAutoLayoutLabel < UILabel
  def layoutSubviews
    super
    if numberOfLines == 0
      if preferredMaxLayoutWidth != frame.size.width
        self.preferredMaxLayoutWidth = frame.size.width
        setNeedsUpdateConstraints
      end
    end
  end
  def intrinsicContentSize
    s = super
    if numberOfLines == 0
      # found out that sometimes intrinsicContentSize is 1pt too short!
      s.height += 1
    end
    s
  end
end
