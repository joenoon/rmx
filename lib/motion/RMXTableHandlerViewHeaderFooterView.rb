class RMXTableHandlerViewHeaderFooterView < UITableViewHeaderFooterView

  include RMXCommonMethods

  RMX.new(self).weak_attr_accessor :tableView
  RMX.new(self).weak_attr_accessor :tableHandler
  attr_accessor :section

  def initWithReuseIdentifier(reuseIdentifier)
    s = super
    setup
    s
  end

  def context=(context)
    self.tableHandler = context[:tableHandler]
    self.tableView = context[:tableView]
    self.section = context[:section]
    self.data = context[:data]
  end

  def setup
  end

  def data
    @data
  end

  def data=(data)
    @data = data
    textLabel.text = data.to_s
  end

end
