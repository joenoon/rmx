module RMXViewControllerPresentation

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.send(:attr_accessor, :viewState)
  end

  module FactoryMethods

    # presentViewController should always be called on the next runloop to avoid quirks.
    # this just wraps that behavior
    def present(opts)
      unless [ :origin, :view_controller, :animated, :completion ].all? { |x| opts.key?(x) }
        raise "Missing RMXViewControllerPresentation.present opts: #{opts.inspect}"
      end
      Dispatch::Queue.main.async do
        opts[:origin].presentViewController(opts[:view_controller], animated:opts[:animated], completion:opts[:completion])
      end
    end

    # remove the controller from the display heirarchy, taking into account how it is
    # currently presented.  avoid nesting animations and corrupting the UI by using
    # whenOrIfViewState and executing on the main thread async to ensure it is not yanked out of the
    # UI during existing animations
    def dismiss(opts)
      unless [ :view_controller, :animated, :completion ].all? { |x| opts.key?(x) }
        raise "Missing RMXViewControllerPresentation.dismiss opts: #{opts.inspect}"
      end
      animated = opts[:animated]
      block = opts[:completion]
      view_controller = opts[:view_controller]
      navigationController = view_controller.navigationController


      if view_controller.presentingViewController
        Dispatch::Queue.main.async do
          view_controller.dismissViewControllerAnimated(animated, completion:block)
        end
      elsif navigationController
        if index = navigationController.viewControllers.index(view_controller)
          before_index = index - 1
          before_index = 0 if index < 0
          pop_to_controller = navigationController.viewControllers[before_index]
          if pop_to_controller && pop_to_controller != navigationController.viewControllers.last
            # p "pop_to_controller", pop_to_controller
            # p "navigationController.popToViewController(pop_to_controller, animated:animated)"
            Dispatch::Queue.main.async do
              RMX.new(navigationController).once(:done_animating, &block) if block
              navigationController.popToViewController(pop_to_controller, animated:animated)
            end
          end
        end
      end
    end

  end
  extend FactoryMethods

  module InstanceMethods

    def triggerViewState!(animated)
      # p "triggerViewState!", @viewState, animated
      RMX.new(self).trigger(@viewState, animated)
    end

    def whenOrIfViewState(viewState, &block)
      if viewState == @viewState
        block.call
      else
        RMX.new(self).once(viewState, &block)
      end
    end

    def appearing(animated)
    end

    def rmx_viewWillAppear(animated)
      @viewState = :viewWillAppear
      triggerViewState!(animated)
      appearing(animated)
    end

    def appeared(animated)
    end

    def rmx_viewDidAppear(animated)
      @viewState = :viewDidAppear
      triggerViewState!(animated)
      appeared(animated)
    end

    def disappearing(animated)
    end

    def rmx_viewWillDisappear(animated)
      @viewState = :viewWillDisappear
      triggerViewState!(animated)
      disappearing(animated)
    end

    def disappeared(animated)
    end

    def rmx_viewDidDisappear(animated)
      @viewState = :viewDidDisappear
      triggerViewState!(animated)
      disappeared(animated)
    end

    def present(vc, animated=false, &block)
      RMXViewControllerPresentation.present({
        :origin => self,
        :view_controller => vc,
        :animated => animated,
        :completion => block
      })
    end
    
    def dismiss(animated=false, &block)
      RMXViewControllerPresentation.dismiss({
        :view_controller => self,
        :animated => animated,
        :completion => block
      })
    end
  end
end
