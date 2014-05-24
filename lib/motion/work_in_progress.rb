module RMExtensions

  def self.app
    UIApplication.sharedApplication
  end

  def self.ios_version
    @ios_version ||= UIDevice.currentDevice.systemVersion.split(".").take(2).join(".").to_f    
  end

  def self.screen_pixel
    1.0 / UIScreen.mainScreen.scale
  end

  def self.keyboardWillChangeFrame(notification)
    @keyboardWillChangeFrameNotification = notification
    processKeyboardWillChange
  end

  def self.processKeyboardWillChange
    return unless notification = @keyboardWillChangeFrameNotification
    info = notification.userInfo
    keyboardFrame = info.objectForKey(UIKeyboardFrameEndUserInfoKey).CGRectValue
    bounds = UIScreen.mainScreen.bounds
    animationDuration = info.objectForKey(UIKeyboardAnimationDurationUserInfoKey).doubleValue
    #  below the screen                              # above the screen                                                       # left of the screen                                                    # right of the screen
    currentKeyboardHeight = if keyboardFrame.origin.y >= bounds.size.height || keyboardFrame.origin.y <= bounds.origin.y - keyboardFrame.size.height || keyboardFrame.origin.x <= bounds.origin.x - keyboardFrame.size.width || keyboardFrame.origin.x >= bounds.size.width
      0
    else
      keyboardFrame.size.height
    end
    # p "================>"
    if currentKeyboardHeight != @currentKeyboardHeight
      @currentKeyboardHeight = currentKeyboardHeight
      # p "currentKeyboardHeight", currentKeyboardHeight
      # p "keyboardFrame", keyboardFrame
      # p "UIScreen.mainScreen.bounds", UIScreen.mainScreen.bounds
      NSNotificationCenter.defaultCenter.postNotificationName("rmextKeyboardChanged", object:nil, userInfo:{
        :height => currentKeyboardHeight,
        :animationDuration => animationDuration
      })
    end
    @keyboardWillChangeFrameNotification = nil
  end

  def self.currentKeyboardHeight
    @currentKeyboardHeight || 0
  end
  NSNotificationCenter.defaultCenter.addObserver(self, selector:'keyboardWillChangeFrame:', name:UIKeyboardWillChangeFrameNotification, object:nil)

  module SetAttributes

    def self.included(klass)
      klass.send(:include, InstanceMethods)
      klass.send(:extend, ClassMethods)
    end

    module InstanceMethods

      def after_attributes_set
      end

      def attributes=(attrs={})
        keys = [] + attrs.keys
        while key = keys.pop
          value = attrs[key]
          self.send("#{key}=", value)
        end
        after_attributes_set
      end

    end

    module ClassMethods

      def create(opts={})
        x = new
        x.attributes = opts
        x
      end

    end

  end

  module ViewControllerPresentation

    def self.included(klass)
      klass.send(:include, InstanceMethods)
      klass.send(:attr_accessor, :viewState)
    end

    module FactoryMethods

      # presentViewController should always be called on the next runloop to avoid quirks.
      # this just wraps that behavior
      def present(opts)
        unless [ :origin, :view_controller, :animated, :completion ].all? { |x| opts.key?(x) }
          raise "Missing ViewControllerPresentation.present opts: #{opts.inspect}"
        end
        rmext_on_main_q do
          opts[:origin].presentViewController(opts[:view_controller], animated:opts[:animated], completion:opts[:completion])
        end
      end

      # remove the controller from the display heirarchy, taking into account how it is
      # currently presented.  avoid nesting animations and corrupting the UI by using
      # whenOrIfViewState and rmext_on_main_q to ensure it is not yanked out of the
      # UI during existing animations
      def dismiss(opts)
        unless [ :view_controller, :animated, :completion ].all? { |x| opts.key?(x) }
          raise "Missing ViewControllerPresentation.dismiss opts: #{opts.inspect}"
        end
        animated = opts[:animated]
        block = opts[:completion]
        view_controller = opts[:view_controller]
        navigationController = view_controller.navigationController
        dismiss_opts = {
          :animated => animated,
          :view_controller => view_controller,
          :presentedViewController => view_controller.presentedViewController,
          :presentingViewController => view_controller.presentingViewController,
          :navigationController => view_controller.navigationController
        }
        perform_dismissal = lambda do
          performed = false
          # p "*"*100
          # p "dismiss", dismiss_opts
          if view_controller.presentingViewController
            # p "presentingViewController.dismissViewControllerAnimated(animated, completion:nil)"
            rmext_on_main_q do
              view_controller.dismissViewControllerAnimated(animated, completion:block)
            end
            performed = true
          elsif navigationController
            # p "navigationController strategy"
            if index = navigationController.viewControllers.index(view_controller)
              before_index = index - 1
              before_index = 0 if index < 0
              pop_to_controller = navigationController.viewControllers[before_index]
              if pop_to_controller && pop_to_controller != navigationController.viewControllers.last
                # p "pop_to_controller", pop_to_controller
                # p "navigationController.popToViewController(pop_to_controller, animated:animated)"
                rmext_on_main_q do
                  if block
                    view_controller.whenOrIfViewState(:viewDidDisappear) do
                      block.call
                    end
                  end
                  navigationController.popToViewController(pop_to_controller, animated:animated)
                end
                performed = true
              end
            end
          end
          if !performed
            p "DID NOT PERFORM dismiss", dismiss_opts
          end
          # p "*"*100
        end
        if view_controller.respondsToSelector('whenOrIfViewState:')
          view_controller.whenOrIfViewState(:viewDidAppear) do
            perform_dismissal.call
          end
        else
          perform_dismissal.call
        end
      end
    end
    extend FactoryMethods

    module InstanceMethods

      def triggerViewState!(animated)
        # p "triggerViewState!", @viewState, animated
        rmext_trigger(@viewState, animated)
      end

      def whenOrIfViewState(viewState, &block)
        if viewState == @viewState
          block.call
        else
          rmext_once(viewState, &block)
        end
      end

      def appearing(animated)
      end

      def rmext_viewWillAppear(animated)
        @viewState = :viewWillAppear
        triggerViewState!(animated)
        appearing(animated)
      end

      def appeared(animated)
      end

      def rmext_viewDidAppear(animated)
        @viewState = :viewDidAppear
        triggerViewState!(animated)
        appeared(animated)
      end

      def disappearing(animated)
      end

      def rmext_viewWillDisappear(animated)
        @viewState = :viewWillDisappear
        triggerViewState!(animated)
        disappearing(animated)
      end

      def disappeared(animated)
      end

      def rmext_viewDidDisappear(animated)
        @viewState = :viewDidDisappear
        triggerViewState!(animated)
        disappeared(animated)
      end

      def present(vc, animated=false, &block)
        ViewControllerPresentation.present({
          :origin => self,
          :view_controller => vc,
          :animated => animated,
          :completion => block
        })
      end
      
      def dismiss(animated=false, &block)
        ViewControllerPresentation.dismiss({
          :view_controller => self,
          :animated => animated,
          :completion => block
        })
      end
    end
  end

  module KeyboardHelpers

    def keyboard_proxy
      keyboard_proxy_constraints unless @keyboard_proxy_constraints
      @keyboard_proxy
    end

    def keyboard_proxy_constraints
      @keyboard_proxy ||= UIView.new
      @keyboard_proxy_constraints ||= begin
        x = {}
        RMExtensions::Layout.new do |layout|
          layout.view = view
          layout.subviews = {
            "keyboard_proxy" => @keyboard_proxy
          }
          x[:bottom] = layout.eq "keyboard_proxy.bottom == #{-RMExtensions.currentKeyboardHeight}"
          x[:height] = layout.eq "keyboard_proxy.height == 0"
        end
        x
      end
    end

    def listenForKeyboardChanged
      NSNotificationCenter.defaultCenter.addObserver(self, selector:'keyboardChangedInternal:', name:"rmextKeyboardChanged", object:nil)
    end

    # listens for the rmextKeyboardChanged notification and extracts the userInfo to call a friendlier method
    def keyboardChangedInternal(notification)
      if isViewLoaded
        info = notification.userInfo
        keyboardChanged(info)
      end
    end

    # by default, looks to see if the controller is using the @keyboard_proxy_constraint convention.
    # if so, sets the constraint's constant and refreshes the layout in the same animationDuration
    # as the keyboard's animation.
    #
    # if you want to do more/other stuff on keyboardChanged, you can override this, call super, or
    # do everything on your own.
    def keyboardChanged(info)
      if constraint = @keyboard_proxy_constraints && @keyboard_proxy_constraints[:height]
        rmext_on_main_q do
          UIView.animateWithDuration(info[:animationDuration], animations: lambda do
            keyboard_proxy_constraints[:bottom].constant = -RMExtensions.currentKeyboardHeight
            view.setNeedsUpdateConstraints
            view.layoutIfNeeded
          end)
        end
      end
    end

  end

  class NavigationController < UINavigationController

    include CommonMethods
    include ViewControllerPresentation

    def viewDidLoad
      s = super
      view.backgroundColor = UIColor.whiteColor
      s
    end

    def viewWillAppear(animated)
      s = super
      rmext_viewWillAppear(animated)
      s
    end

    def viewDidAppear(animated)
      s = super
      rmext_viewDidAppear(animated)
      s
    end

    def viewWillDisappear(animated)
      s = super
      resignApplicationFirstResponder
      rmext_viewWillDisappear(animated)
      s
    end

    def viewDidDisappear(animated)
      s = super
      rmext_viewDidDisappear(animated)
      s
    end

    def resignApplicationFirstResponder
      windows = [] + UIApplication.sharedApplication.windows
      while window = windows.pop
        window.endEditing(true)
      end
    end

    def didReceiveMemoryWarning
      p "didReceiveMemoryWarning"
      super
    end

    def self.create(rootViewController)
      v = alloc.initWithNavigationBarClass(UINavigationBar, toolbarClass:nil)
      v.delegate = v
      v.pushViewController(rootViewController, animated: false) if rootViewController
      v
    end
    
  end

  class TableViewController < UITableViewController

    include CommonMethods
    include ViewControllerPresentation
    include KeyboardHelpers
    include SetAttributes

    def prepare
    end

    def loaded
    end

    def init
      s = super
      if RMExtensions.ios_version >= 7.0
        self.edgesForExtendedLayout = UIRectEdgeNone
        self.automaticallyAdjustsScrollViewInsets = false
      end
      NSNotificationCenter.defaultCenter.addObserver(self, selector:'refresh', name:UIApplicationWillEnterForegroundNotification, object:nil)
      listenForKeyboardChanged
      prepare
      s
    end

    def refresh
    end

    def viewDidLoad
      view.backgroundColor = UIColor.whiteColor
      s = super
      loaded
      s
    end

    def viewWillAppear(animated)
      s = super
      rmext_viewWillAppear(animated)
      s
    end

    def viewDidAppear(animated)
      s = super
      rmext_viewDidAppear(animated)
      s
    end

    def viewWillDisappear(animated)
      s = super
      rmext_viewWillDisappear(animated)
      s
    end

    def viewDidDisappear(animated)
      s = super
      rmext_viewDidDisappear(animated)
      s
    end

    def didReceiveMemoryWarning
      p "didReceiveMemoryWarning"
      super
    end
    
    def rmext_dealloc
      common_deallocs
      super
    end

  end

  class ViewController < UIViewController

    include CommonMethods
    include ViewControllerPresentation
    include KeyboardHelpers
    include SetAttributes

    def init
      s = super
      if RMExtensions.ios_version >= 7.0
        self.edgesForExtendedLayout = UIRectEdgeNone
        self.automaticallyAdjustsScrollViewInsets = false
      end
      NSNotificationCenter.defaultCenter.addObserver(self, selector:'refresh', name:UIApplicationWillEnterForegroundNotification, object:nil)
      listenForKeyboardChanged
      prepare
      s
    end

    def prepare
    end

    def loaded
    end

    def refresh
    end

    def viewDidLoad
      view.backgroundColor = UIColor.whiteColor
      s = super
      loaded
      s
    end

    def viewWillAppear(animated)
      s = super
      rmext_viewWillAppear(animated)
      s
    end

    def viewDidAppear(animated)
      s = super
      rmext_viewDidAppear(animated)
      s
    end

    def viewWillDisappear(animated)
      s = super
      rmext_viewWillDisappear(animated)
      s
    end

    def viewDidDisappear(animated)
      s = super
      rmext_viewDidDisappear(animated)
      s
    end

    def didReceiveMemoryWarning
      p "didReceiveMemoryWarning"
      super
    end

    def rmext_dealloc
      common_deallocs
      super
    end

  end

  class SegmentedController < ViewController

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

    def rmext_dealloc
      cleanup_active
      @controller_indexes = nil
    end

  end

  class View < UIView

    include CommonMethods
    include SetAttributes

    attr_accessor :updatedSize, :reportSizeChanges

    def rmext_dealloc
      common_deallocs
      super
    end

    def prepare
    end

    def setup
    end

    def init
      s = super
      prepare
      setUserInteractionEnabled(false)
      setup
      s
    end

    def setUserInteractionEnabled(bool)
      @userInteractionEnabled = bool
    end

    def self.create(attributes={})
      x = new
      x.attributes = attributes
      x
    end

    # normal userInteractionEnabled means the view and all subviews can't be clicked.  what we normally
    # want is subviews to be clickable, but not the parent.  this custom hitTest allows that behavior.
    def hitTest(point, withEvent:event)
      s = super
      if s == self && @userInteractionEnabled == false
        return nil
      end
      s
    end

    def requiresConstraintBasedLayout
      true
    end

    def layoutSubviews
      s = super
      if reportSizeChanges
        rmext_on_main_q do
          size = systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
          unless updatedSize == size
            self.updatedSize = size
            rmext_trigger(:updatedSize, size)
            
            if tableView = is_or_within_a?(UITableView)
              if tableView.delegate.respondsToSelector('tableView:viewDidUpdateSize:')
                tableView.delegate.tableView(tableView, viewDidUpdateSize:self)
              end
              # p "unbounced reload"
              rmext_debounce(:reloadTableUpdatedSize) do
                # p "debounced reload"
                if controller = tableView.lAncestorViewController
                  if controller.viewState == :viewDidAppear
                    tableView.beginUpdates
                    tableView.endUpdates
                  else
                    tableView.reloadData
                  end
                end
              end
            end

          end
        end
      end
      s
    end

  end

  class ActionSheet < UIActionSheet

    def init
      s = super
      self.delegate = self
      s
    end

    def actionSheet(actionSheet, clickedButtonAtIndex:buttonIndex)
      title = actionSheet.buttonTitleAtIndex(buttonIndex)
      rmext_trigger(:clickedButton, { :index => buttonIndex, :title => title })
    end

  end

  class AutoLayoutLabel < UILabel
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

  class AutoLayoutScrollView < UIScrollView
    class FollowView < UIView
      rmext_weak_attr_accessor :fittedView
      def layoutSubviews
        s = super
        fittedView.invalidateIntrinsicContentSize
        fittedView.setNeedsUpdateConstraints
        fittedView.layoutIfNeeded
        s
      end
    end
    class FittedView < UIView
      rmext_weak_attr_accessor :followView
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
      RMExtensions::Layout.new do |layout|
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
      RMExtensions::Layout.new do |layout|
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

  class TableHandler

    include CommonMethods

    rmext_weak_attr_accessor :tableView, :delegate

    attr_accessor :registered_reuse_identifiers, :sections

    def self.forTable(tableView)
      x = new
      x.tableView = tableView
      tableView.dataSource = x
      tableView.delegate = x
      x
    end

    def rmext_dealloc
      if tv = tableView
        tv.dataSource = nil
        tv.delegate = nil
      end
      rmext_nil_instance_variables!
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

    def tableView(tableView, cellForRowAtIndexPath:indexPath)
      rmext_assert_main_thread!
      context = {
        :tableHandler => self,
        :tableView => tableView,
        :indexPath => indexPath,
        :data => delegate.tableHandler(self, dataForSectionName:@sections[indexPath.section])[indexPath.row]
      }
      res = delegate.tableHandler(self, cellOptsForContext:context)
      if res.is_a?(Hash)
        context.update(res)
        unless res[:reuseIdentifier]
          raise ":reuseIdentifier is required"
        end
        reuseIdentifier = res[:reuseIdentifier].to_s
        registered_reuse_identifiers[reuseIdentifier] || registerClass(TableViewCell, forCellReuseIdentifier:reuseIdentifier)
        res = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath:indexPath)
        res.context = context
      end
      # p "cellForRowAtIndexPath", res, context
      res
    end

    def tableView(tableView, heightForRowAtIndexPath:indexPath)
      rmext_assert_main_thread!
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
      if res.is_a?(Hash)
        context.update(res)
        unless res[:reuseIdentifier]
          raise ":reuseIdentifier is required"
        end
        reuseIdentifier = res[:reuseIdentifier].to_s
        height = nil
        if res[:data]
          if heights = @heights[reuseIdentifier]
            height = heights[res[:data]]
          end
        end
        unless height
          # p "using estimated"
          height = res[:estimated]
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
      rmext_assert_main_thread!
      if @respondsToHeaderForContext || delegate.respondsToSelector('tableHandler:headerForContext:')
        @respondsToHeaderForContext = true
        context = {
          :tableHandler => self,
          :tableView => tableView,
          :section => section
        }
        res = delegate.tableHandler(self, headerForContext:context)
        # p "viewForHeaderInSection", section, res
        res
      end
    end

    def tableView(tableView, heightForHeaderInSection:section)
      rmext_assert_main_thread!
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
      rmext_assert_main_thread!
      res = delegate.tableHandler(self, dataForSectionName:@sections[section]).size
      # p "numberOfRowsInSection", res
      res
    end

    def numberOfSectionsInTableView(tableView)
      rmext_assert_main_thread!
      res = @sections.size
      # p "numberOfSectionsInTableView", res
      res
    end

    def tableView(tableView, didSelectRowAtIndexPath:indexPath)
      rmext_assert_main_thread!
      if @respondsToClickForContext || delegate.respondsToSelector('tableHandler:clickForContext:')
        @respondsToClickForContext = true
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

  class TableViewCell < UITableViewCell

    include CommonMethods

    rmext_weak_attr_accessor :tableView
    rmext_weak_attr_accessor :tableHandler
    attr_accessor :indexPath, :innerContentView

    def initWithStyle(style, reuseIdentifier:reuseIdentifier)
      reuseIdentifier = reuseIdentifier.to_s
      s = super(style, reuseIdentifier)
      @innerContentView = TableViewCellInnerContentView.new
      @innerContentView.cell = self
      RMExtensions::Layout.new do |layout|
        layout.view = contentView
        layout.subviews = {
          "innerContentView" => @innerContentView
        }
        layout.eqs %Q{
          innerContentView.top == 0
          innerContentView.left == 0
          innerContentView.right == 0
          innerContentView.bottom == 0 @ med
        }
      end
      setup
      s
    end

    def context=(context)
      self.tableHandler = context[:tableHandler]
      self.tableView = context[:tableView]
      self.indexPath = context[:indexPath]
      self.data = context[:data]
      self.view = context[:view]
      if context[:transform] && transform != context[:transform]
        self.transform = context[:transform]
      end
    end

    def setup
    end

    def data
      @data
    end

    def data=(data)
      @data = data
    end

    def view
      @view
    end

    def view=(view)
      @view.removeFromSuperview if @view
      if @view = view
        RMExtensions::Layout.new do |layout|
          layout.view = innerContentView
          layout.subviews = {
            "tile" => view
          }
          layout.eqs %Q{
            tile.top == 0
            tile.left == 0
            tile.right == 0
            tile.bottom == 0 @ 500
          }
        end
      end
      view
    end

    def updateHeight!
      if (d = data) && (h = tableHandler)
        height = contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        # p "height", height
        if h.updateHeight(height, data:d, reuseIdentifier:reuseIdentifier)
          h.reloadData
        end
      end
    end

  end

  class TableViewCellInnerContentView < View
    rmext_weak_attr_accessor :cell
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

end
