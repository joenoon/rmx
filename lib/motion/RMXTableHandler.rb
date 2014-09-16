class RMXTableHandler

  # required delegate method:
  #
  # def tableHandler(tableHandler, optsForData:data, section:section, row:row)
  #   example return:
  #     {
  #       :reuseIdentifier => "reuseIdentifier", # semi-required unless using static :cell (an empty cell will be used otherwise)
  #       :estimated_height => 100, # setting this will improve performance
  #       :fixed_height => 100, # if you know the cells height, setting this will greatly improve performance
  #       :cell => aTableViewCell # static
  #     }
  #
  # def tableHandler(tableHandler, dataForSection:section)
  #   example return if only using one section:
  #     @my_array_of_data
  #   example return if using multiple sections:
  #     @my_array_of_arrays_of_data[section]
  #
  # optional:
  #
  # def tableHandler(tableHandler, clickForData:data, section:section, row:row) # if not implemented cell will be no-select
  # def tableHandler(tableHandler, numberOfRowsInSection:section) # default (dataForSection:).size
  # def numberOfSectionsInTableHandler(tableHandler) # default 1
  # def tableHandler(tableHandler, optsForSection:section)
  #   if title = @headers[section]
  #     {
  #       :reuseIdentifier => :section_header,
  #       :data => title,
  #       :fixed_height => 30  # required,
  #       :header => aHeaderView # static
  #     }
  #   end
  # end

  #

  include RMXCommonMethods

  RMX.new(self).weak_attr_accessor :tableView, :delegate

  attr_accessor :registered_reuse_identifiers, :debug, :allowRefreshHeights

  def self.forTable(tableView, delegate:delegate)
    x = new
    if tableView.respondsToSelector('setLayoutMargins:')
      tableView.layoutMargins = UIEdgeInsetsZero
    end
    x.tableView = tableView
    x.delegate = delegate
    tableView.dataSource = x
    tableView.delegate = x
    x.registerClass(RMXTableHandlerViewCell, forCellReuseIdentifier:"Empty")
    x
  end

  def initialize
    @debug = false
    @heights = {}
    @registered_reuse_identifiers = {}
    @delegateRespondsTo = {}
    @allowRefreshHeights = false
    @animateUpdatesSignal = RACSubject.subject
    @animateUpdatesSignal
    .throttle(0.25)
    .deliverOn(RACScheduler.mainThreadScheduler)
    .subscribeNext(->(v) {
      animateUpdates
    }.rmx_weak!(nil, "animateUpdates"))

    rac_willDeallocSignal.subscribeCompleted(-> {
      if tv = tableView
        tv.dataSource = nil
        tv.delegate = nil
      end
    }.rmx_unsafe!)
    self
  end

  def animateUpdates
    RMX.after_animations do
      if tv = tableView and tv.superview
        tv.beginUpdates
        tv.endUpdates
      end
    end
  end

  def reloadData
    if tv = tableView
      log("reloadData") if debug
      @allowRefreshHeights = false
      tv.reloadData
      @allowRefreshHeights = true
    end
  end

  def cached_height_for_data(data, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    sizerCell = registered_reuse_identifiers[reuseIdentifier]
    sizerCell.data = data
    height = sizerCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
    @heights[[ reuseIdentifier, data ]] = height
    log("cached_height_for_data", data, height) if debug
    height
  end

  def log(*args)
    args.unshift debug
    p *args
  end

  def invalidateHeightForData(data, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    @heights.delete([ reuseIdentifier, data ])
    log("invalidateHeightForData", reuseIdentifier, data) if debug
    if allowRefreshHeights
      log("invalidateHeightForData animateUpdates") if debug
      @animateUpdatesSignal.sendNext(true)
    else
      log("invalidateHeightForData animateUpdates skipped because of allowRefreshHeights == false") if debug
    end
  end

  def registerClass(klass, forCellReuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    registered_reuse_identifiers[reuseIdentifier] = sizerCell = klass.new
    sizerCell.tableHandler = self
    sizerCell.sizerCellReuseIdentifier = reuseIdentifier
    tableView.registerClass(klass, forCellReuseIdentifier:reuseIdentifier)
  end

  def registerClass(klass, forHeaderFooterViewReuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    registered_reuse_identifiers[reuseIdentifier] = klass.new
    tableView.registerClass(klass, forHeaderFooterViewReuseIdentifier:reuseIdentifier)
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    data = delegate.tableHandler(self, dataForSection:indexPath.section)[indexPath.row]
    opts = delegate.tableHandler(self, optsForData:data, section:indexPath.section, row:indexPath.row) || {}
    reuseIdentifier = opts[:reuseIdentifier].to_s
    context = {
      :tableHandler => self,
      :tableView => tableView,
      :indexPath => indexPath,
      :data => data
    }
    cell = nil
    if cell = opts[:cell]
      # noop
    elsif reuseIdentifier.empty? || !registered_reuse_identifiers.key?(reuseIdentifier)
      log("Unknown reuseIdentifier '#{reuseIdentifier}'", context)
      cell = tableView.dequeueReusableCellWithIdentifier("Empty", forIndexPath:indexPath)
    else
      context.update(opts)
      cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath:indexPath)
      cell.context = context
    end
    unless delegateRespondsTo?('tableHandler:clickForData:section:row:')
      cell.selectionStyle = UITableViewCellSelectionStyleNone
    end
    log("cellForRowAtIndexPath", indexPath.description, cell, context) if debug
    cell
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath)
    heightForRowAtIndexPath(indexPath, false)
  end

  def tableView(tableView, estimatedHeightForRowAtIndexPath:indexPath)
    heightForRowAtIndexPath(indexPath, true)
  end

  def heightForRowAtIndexPath(indexPath, allow_estimated=false)
    data = delegate.tableHandler(self, dataForSection:indexPath.section)[indexPath.row]
    opts = delegate.tableHandler(self, optsForData:data, section:indexPath.section, row:indexPath.row) || {}
    reuseIdentifier = opts[:reuseIdentifier].to_s
    height = nil
    type = :empty
    unless height = (reuseIdentifier.empty? || !registered_reuse_identifiers.key?(reuseIdentifier)) && 0
      type = :fixed
      unless height = opts[:fixed_height]
        type = :cached
        unless height = @heights[[ reuseIdentifier, data ]]
          type = :estimated
          unless allow_estimated and height = opts[:estimated_height]
            type = :calculated
            height = cached_height_for_data(data, reuseIdentifier:reuseIdentifier)
          end
        end
      end
    end
    log("heightForRowAtIndexPath", allow_estimated, indexPath.description, type, height) if debug
    height
  end

  def delegateRespondsTo?(sel)
    if @delegateRespondsTo[sel].nil?
      @delegateRespondsTo[sel] = delegate.respondsToSelector(sel)
    end
    @delegateRespondsTo[sel]
  end

  def tableView(tableView, viewForHeaderInSection:section)
    if delegateRespondsTo?('tableHandler:optsForSection:')
      context = {
        :tableHandler => self,
        :tableView => tableView,
        :section => section
      }
      opts = delegate.tableHandler(self, optsForSection:section) || {}
      reuseIdentifier = opts[:reuseIdentifier].to_s
      header = nil
      if header = opts[:header]
        # noop
      elsif reuseIdentifier.empty? || !registered_reuse_identifiers.key?(reuseIdentifier)
        log("Unknown reuseIdentifier '#{reuseIdentifier}'", context)
      else
        context.update(opts)
        header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(reuseIdentifier)
        header.context = context
      end
      log("viewForHeaderInSection", section, header) if debug
      header
    end
  end

  def tableView(tableView, heightForHeaderInSection:section)
    height = nil
    if delegateRespondsTo?('tableHandler:optsForSection:')
      opts = delegate.tableHandler(self, optsForSection:section) || {}
      reuseIdentifier = opts[:reuseIdentifier].to_s
      type = :empty
      unless height = (reuseIdentifier.empty? || !registered_reuse_identifiers.key?(reuseIdentifier)) && 0
        type = :fixed
        height = opts[:fixed_height]
      end
    end
    height ||= 0
    log("heightForHeaderInSection", section, height) if debug
    height
  end

  def tableView(tableView, numberOfRowsInSection:section)
    res = if delegateRespondsTo?('tableHandler:numberOfRowsInSection:')
      delegate.tableHandler(self, numberOfRowsInSection:section)
    else
      delegate.tableHandler(self, dataForSection:section).size
    end
    log("numberOfRowsInSection", res) if debug
    res
  end

  def numberOfSectionsInTableView(tableView)
    res = if delegateRespondsTo?('numberOfSectionsInTableHandler:')
      delegate.numberOfSectionsInTableHandler(self)
    else
      1
    end
    log("numberOfSectionsInTableView", res) if debug
    res
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    if delegateRespondsTo?('tableHandler:clickForData:section:row:')
      data = delegate.tableHandler(self, dataForSection:indexPath.section)[indexPath.row]
      delegate.tableHandler(self, clickForData:data, section:indexPath.section, row:indexPath.row)
      tableView.deselectRowAtIndexPath(indexPath, animated:true)
    end
  end

end
