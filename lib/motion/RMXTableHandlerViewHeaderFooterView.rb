class RMXTableHandlerViewHeaderFooterView < RMXTableViewHeaderFooterView

  RMX.new(self).weak_attr_accessor :rmx_tableView
  RMX.new(self).weak_attr_accessor :tableHandler
  attr_accessor :section

  def tableView
    self.rmx_tableView
  end

  def context=(context)
    self.tableHandler = context[:tableHandler]
    self.rmx_tableView = context[:tableView]
    self.section = context[:section]
    self.data = context[:data]
  end

  def data
    @data
  end

  def data=(data)
    @data = data
    textLabel.text = data.to_s
  end

end
