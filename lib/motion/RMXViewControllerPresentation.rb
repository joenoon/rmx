module RMXViewControllerPresentation

  def self.included(klass)
    klass.send(:include, InstanceMethods)
  end

  module InstanceMethods

    def viewStateSignal
      @viewStateSignal ||= begin
        sub = RACReplaySubject.replaySubjectWithCapacity(1)

        RACSignal.merge([
          rac_signalForSelector('viewWillAppear:').map(->(tuple) { [ :viewWillAppear, tuple.first ] }.weak!),
          rac_signalForSelector('viewDidAppear:').map(->(tuple) { [ :viewDidAppear, tuple.first ] }.weak!),
          rac_signalForSelector('viewWillDisappear:').map(->(tuple) { [ :viewWillDisappear, tuple.first ] }.weak!),
          rac_signalForSelector('viewDidDisappear:').map(->(tuple) { [ :viewDidDisappear, tuple.first ] }.weak!)
        ])
        .takeUntil(rac_willDeallocSignal)
        .subscribeNext(->(v) {
          sub.sendNext(v)
        }.weak!)

        rac_signalForSelector('viewWillAppear:').subscribeNext(->(tuple) { appearing(tuple.first) }.weak!)
        rac_signalForSelector('viewDidAppear:').subscribeNext(->(tuple) { appeared(tuple.first) }.weak!)
        rac_signalForSelector('viewWillDisappear:').subscribeNext(->(tuple) { disappearing(tuple.first) }.weak!)
        rac_signalForSelector('viewDidDisappear:').subscribeNext(->(tuple) { disappeared(tuple.first) }.weak!)

        sub.subscribeOn(RACScheduler.mainThreadScheduler).deliverOn(RACScheduler.mainThreadScheduler).takeUntil(rac_willDeallocSignal)
      end
    end

    def viewStateFilteredSignal(state)
      viewStateSignal
      .filter(->((_state, animated)) {
        state == _state
      }.weak!)
    end

    def viewStateFilteredOnceSignal(state)
      viewStateFilteredSignal(state).take(1)
    end

    def appearing(animated)
    end

    def appeared(animated)
    end

    def disappearing(animated)
    end

    def disappeared(animated)
    end

  end
end
