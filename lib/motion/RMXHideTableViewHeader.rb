module RMXHideTableViewHeader

  def hideHeaderForTableView(tableView)
    Dispatch::Queue.main.async do
      tableView.contentOffset = CGPointMake(0, tableView.tableHeaderView.bounds.size.height - topLayoutGuide.length)
    end
    true
  end

end
