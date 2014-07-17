class RMXTableHandler

  include RMXCommonMethods

  RMX.new(self).weak_attr_accessor :tableView, :delegate

  attr_accessor :registered_reuse_identifiers, :sections

  def self.forTable(tableView)
    x = new
    x.tableView = tableView
    tableView.dataSource = x
    tableView.delegate = x
    x.registerClass(RMXTableHandlerViewCell, forCellReuseIdentifier:"Empty")
    x
  end

  def rmx_dealloc
    if tv = tableView
      tv.dataSource = nil
      tv.delegate = nil
    end
    RMX.new(self).nil_instance_variables!
    super
  end

  def initialize
    @sections = []
    @heights = {}
    @registered_reuse_identifiers = {}
    self
  end

  def animateUpdates
    if @isAnimatingUpdates
      @animateUpdatesAgain = true
      return
    end
    @isAnimatingUpdates = true
    CATransaction.begin
    CATransaction.setCompletionBlock(lambda do
      p "animation has finished"
      @isAnimatingUpdates = false
      if @animateUpdatesAgain
        p "animate again!"
        @animateUpdatesAgain = false
        animateUpdates
      end
    end)
    tableView.beginUpdates
    tableView.endUpdates
    CATransaction.commit
  end

  def reloadData
    if tv = tableView
      tv.reloadData
    end
  end

  def set_size_for_data(data, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    sizerCell = registered_reuse_identifiers[reuseIdentifier]
    sizerCell.data = data
    height = sizerCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
    updateHeight(height, data:data, reuseIdentifier:reuseIdentifier)
  end

  def registerClass(klass, forCellReuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    registered_reuse_identifiers[reuseIdentifier] = klass.new
    tableView.registerClass(klass, forCellReuseIdentifier:reuseIdentifier)
  end

  def registerClass(klass, forHeaderFooterViewReuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    registered_reuse_identifiers[reuseIdentifier] = klass.new
    tableView.registerClass(klass, forHeaderFooterViewReuseIdentifier:reuseIdentifier)
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    RMX.assert_main_thread!
    context = {
      :tableHandler => self,
      :tableView => tableView,
      :indexPath => indexPath,
      :data => delegate.tableHandler(self, dataForSectionName:@sections[indexPath.section])[indexPath.row]
    }
    res = delegate.tableHandler(self, cellOptsForContext:context)
    if res.nil?
      res = tableView.dequeueReusableCellWithIdentifier("Empty", forIndexPath:indexPath)
    elsif res.is_a?(Hash)
      context.update(res)
      unless res[:reuseIdentifier]
        raise ":reuseIdentifier is required. context: #{context.inspect}"
      end
      reuseIdentifier = res[:reuseIdentifier].to_s
      res = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath:indexPath)
      unless res
        raise "Missing dequeue, maybe you want: registerClass(RMXTableHandlerViewCell, forCellReuseIdentifier: #{reuseIdentifier.inspect})"
      end
      res.context = context
    end
    unless respondsToClickForContext?
      res.selectionStyle = UITableViewCellSelectionStyleNone
    end
    # p "cellForRowAtIndexPath", res, context
    res
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath)
    RMX.assert_main_thread!
    context = {
      :tableHandler => self,
      :tableView => tableView,
      :indexPath => indexPath,
      :data => delegate.tableHandler(self, dataForSectionName:@sections[indexPath.section])[indexPath.row]
    }
    res = if @respondsToHeightForContext || delegate.respondsToSelector('tableHandler:heightForContext:')
      @respondsToHeightForContext = true
      delegate.tableHandler(self, heightForContext:context)
    else
      delegate.tableHandler(self, cellOptsForContext:context)
    end
    if res.nil?
      res = 0
    elsif res.is_a?(Hash)
      context.update(res)
      unless context[:reuseIdentifier]
        raise ":reuseIdentifier is required. context: #{context.inspect}"
      end
      reuseIdentifier = context[:reuseIdentifier].to_s
      height = nil
      if context[:data]
        if heights = @heights[reuseIdentifier]
          height = heights[context[:data]]
        end
      end
      unless height
        # p "using estimated"
        height = context[:estimated]
      # else
      #   p "using real"
      end
      res = height
    end
    # p "heightForRowAtIndexPath", indexPath, res
    res
  end

  def tableView(tableView, estimatedHeightForRowAtIndexPath:indexPath)
    tableView(tableView, heightForRowAtIndexPath:indexPath)
  end

  def tableView(tableView, viewForHeaderInSection:section)
    RMX.assert_main_thread!
    if @respondsToHeaderForContext || delegate.respondsToSelector('tableHandler:headerForContext:')
      @respondsToHeaderForContext = true
      context = {
        :tableHandler => self,
        :tableView => tableView,
        :section => section
      }
      res = delegate.tableHandler(self, headerForContext:context)
      if res.is_a?(Hash)
        res[:data] ||= @sections[section]
        context.update(res)
        unless res[:reuseIdentifier]
          raise ":reuseIdentifier is required"
        end
        reuseIdentifier = res[:reuseIdentifier].to_s
        res = tableView.dequeueReusableHeaderFooterViewWithIdentifier(reuseIdentifier)
        unless res
          raise "Missing dequeue, maybe you want: registerClass(RMXTableHandlerViewHeaderFooterView, forHeaderFooterViewReuseIdentifier: #{reuseIdentifier.inspect})"
        end
        res.context = context
      end
      # p "viewForHeaderInSection", section, res
      res
    end
  end

  def tableView(tableView, heightForHeaderInSection:section)
    RMX.assert_main_thread!
    if @respondsToHeaderHeightForContext || delegate.respondsToSelector('tableHandler:headerHeightForContext:')
      @respondsToHeaderHeightForContext = true
      context = {
        :tableHandler => self,
        :tableView => tableView,
        :section => section
      }
      res = delegate.tableHandler(self, headerHeightForContext:context)
      # p "heightForHeaderInSection", section, res
      res
    else
      0
    end
  end

  def tableView(tableView, numberOfRowsInSection: section)
    RMX.assert_main_thread!
    res = delegate.tableHandler(self, dataForSectionName:@sections[section]).size
    # p "numberOfRowsInSection", res
    res
  end

  def numberOfSectionsInTableView(tableView)
    RMX.assert_main_thread!
    res = @sections.size
    # p "numberOfSectionsInTableView", res
    res
  end

  def respondsToClickForContext?
    if @respondsToClickForContext || delegate.respondsToSelector('tableHandler:clickForContext:')
      @respondsToClickForContext = true
    end
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    RMX.assert_main_thread!
    if respondsToClickForContext?
      context = {
        :tableHandler => self,
        :tableView => tableView,
        :indexPath => indexPath,
        :data => delegate.tableHandler(self, dataForSectionName:@sections[indexPath.section])[indexPath.row]
      }
      delegate.tableHandler(self, clickForContext:context)
      tableView.deselectRowAtIndexPath(indexPath, animated:true)
    end
  end

  def updateHeight(height, data:data, reuseIdentifier:reuseIdentifier)
    reuseIdentifier = reuseIdentifier.to_s
    @heights[reuseIdentifier] ||= {}
    heights = @heights[reuseIdentifier]
    current_height = heights[data]
    if current_height != height
      heights[data] = height
      return true
    end
    false
  end

end
