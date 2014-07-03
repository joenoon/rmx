class RMXTableViewCell < UITableViewCell

  include RMXCommonMethods

  def initWithStyle(style, reuseIdentifier:reuseIdentifier)
    s = super
    setup
    s
  end

  def setup
  end

end
