module RMXViewControllerPresentation

  def self.included(klass)
    klass.send(:include, InstanceMethods)
  end

  module FactoryMethods

    # presentViewController should always be called on the next runloop to avoid quirks.
    # this just wraps that behavior
    def present(opts)
      unless [ :origin, :view_controller, :animated, :completion ].all? { |x| opts.key?(x) }
        raise "Missing RMXViewControllerPresentation.present opts: #{opts.inspect}"
      end
      RACScheduler.mainThreadScheduler.schedule(-> {
        opts[:origin].presentViewController(opts[:view_controller], animated:opts[:animated], completion:opts[:completion])
      })
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
        RACScheduler.mainThreadScheduler.schedule(-> {
          view_controller.dismissViewControllerAnimated(animated, completion:block)
        })
      elsif navigationController
        if index = navigationController.viewControllers.index(view_controller)
          before_index = index - 1
          before_index = 0 if index < 0
          pop_to_controller = navigationController.viewControllers[before_index]
          if pop_to_controller && pop_to_controller != navigationController.viewControllers.last
            # p "pop_to_controller", pop_to_controller
            # p "navigationController.popToViewController(pop_to_controller, animated:animated)"
            RACScheduler.mainThreadScheduler.schedule(-> {
              if block
                pop_to_controller.rac_signalForSelector('viewDidAppear:')
                .timeout(2, onScheduler:RACScheduler.mainThreadScheduler)
                .take(1)
                .subscribeNext(->(args) {
                  block.call
                }, error:->(error) {
                })
              end
              navigationController.popToViewController(pop_to_controller, animated:animated)
            })
          end
        end
      end
    end

  end
  extend FactoryMethods

  module InstanceMethods

    def viewStateSignal
      @viewStateSignal ||= begin
        sub = RACReplaySubject.replaySubjectWithCapacity(1)

        RACSignal.merge([
          rac_signalForSelector('viewWillAppear:').map(->(v) { :viewWillAppear }.weak!),
          rac_signalForSelector('viewDidAppear:').map(->(v) { :viewDidAppear }.weak!),
          rac_signalForSelector('viewWillDisappear:').map(->(v) { :viewWillDisappear }.weak!),
          rac_signalForSelector('viewDidDisappear:').map(->(v) { :viewDidDisappear }.weak!)
        ])
        .takeUntil(rac_willDeallocSignal)
        .subscribeNext(->(v) {
          sub.sendNext(v)
        }.weak!)

        rac_signalForSelector('viewWillAppear:').subscribeNext(->(tuple) { appearing(tuple.first) }.weak!)
        rac_signalForSelector('viewDidAppear:').subscribeNext(->(tuple) { appeared(tuple.first) }.weak!)
        rac_signalForSelector('viewWillDisappear:').subscribeNext(->(tuple) { disappearing(tuple.first) }.weak!)
        rac_signalForSelector('viewDidDisappear:').subscribeNext(->(tuple) { disappeared(tuple.first) }.weak!)

        sub.takeUntil(rac_willDeallocSignal).subscribeOn(RACScheduler.mainThreadScheduler)
      end
    end

    def whenOrIfViewState(viewState, &block)
      viewStateSignal
      .filter(->(v) {
        v == viewState
      })
      .take(1)
      .deliverOn(RACScheduler.mainThreadScheduler)
      .subscribeNext(->(v) {
        block.call
      })
    end

    def appearing(animated)
    end

    def appeared(animated)
    end

    def disappearing(animated)
    end

    def disappeared(animated)
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
