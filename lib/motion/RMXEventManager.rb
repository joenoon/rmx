# RMXEventManager
#
# This is a convenience layer to EKEventStore.
#
# Subclass and override: `firstDate`, `lastDate`
#
# By default, will load all events between `firstDate` and `lastDate` in all
# selected calendars (defaults to all available) accessible into the `events` accessor.
#
# `newCalendarChooser` creates an EKCalendarChooser that shows the currently selected
# calendars and lets the user select/deselect, then remembers their choice and refreshes
# events.  You should push or present the controller returned.  It will be dismissed
# accordingly when the user clicks Cancel or Done, with the same animation bool that
# was used to display it.  Internally this uses `selectedCalendarObjects` and
# `selectedCalendarObjects=`.  You will probably only need to present the controller
# and everything else is handled automatically:
#
#   navigationController.pushViewController(PZOEventManager.shared.newCalendarChooser, animated:true)
#
# `eventsSignal` is a rac property observer on `events`
#
# `enableRefresh` will start listening and buffering the following events 0.5s:
#   app launch, returning from background, event store changes
#
# `disableRefresh` will stop listening for events that would trigger a refresh
#
# `promptForAccess` or `accessSignal` should be called when you are comfortable with displaying
# the permissions alert to obtain access to calendars.  If access is already granted, this does
# nothing. Until access is granted, `events` will be an empty array. `promptForAccess` is
# fire-and-forget, while `accessSignal` needs to be subscribed to before it will do anything.
#
# You will likely want to set things up like this:
#
#   class MySubclassEventManager < RMXEventManager
#     def firstDate
#       Time.now - (60 * 60 * 24 * 90 * 1)
#     end
#     def lastDate
#       Time.now + (60 * 60 * 24 * 365 * 1)
#     end
#   end
#   MySubclassEventManager.shared.enableRefresh
#
# To further customize, you can override the private methods: `loadEvents` and `_loadEvents`
#
class RMXEventManager

  # for logging status changes
  STATUSES = {
    EKAuthorizationStatusNotDetermined => "EKAuthorizationStatusNotDetermined",
    EKAuthorizationStatusRestricted => "EKAuthorizationStatusRestricted",
    EKAuthorizationStatusDenied => "EKAuthorizationStatusDenied",
    EKAuthorizationStatusAuthorized => "EKAuthorizationStatusAuthorized",
    nil => "Not Set"
  }

  # the current EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
  attr_accessor :status

  # a bool based on `status`, true if EKAuthorizationStatusAuthorized, otherwise false
  attr_accessor :granted

  attr_accessor :events

  attr_accessor :sources, :selectedCalendars, :calendar, :store

  attr_reader :refreshSignal, :eventsSignal

  # override
  def firstDate
    Time.now - (60 * 60 * 24)
  end

  # override
  def lastDate
    Time.now + (60 * 60 * 24)
  end

  # override
  def selectedCalendarsKey
    "#{className}SelectedCalendars"
  end

  def initialize
    @calendar = NSCalendar.autoupdatingCurrentCalendar
    @store = EKEventStore.new
    @events = []

    @status = _status
    @granted = _authorized?

    @sources = []
    @selectedCalendars = NSMutableSet.new

    @refreshSignal = RACSignal.merge([
      RMX.rac_appDidFinishLaunchingNotification,
      RMX.rac_appDidBecomeActiveFromBackground
    ])
    .bufferWithTime(0.5, onScheduler:RACScheduler.mainThreadScheduler)
    .takeUntil(rac_willDeallocSignal)

    @eventsSignal = RMX(self).racObserve("events")

    # log status changes
    RMX(self).racObserve("status")
    .distinctUntilChanged
    .subscribeNext(->(s) {
      NSLog("[#{className}] status=#{STATUSES[s]}")
    }.weak!)

  end

  def self.shared
    Dispatch.once { @shared = new }
    @shared
  end

  def enableRefresh
    @refreshDisposable = @refreshSignal
    .takeUntil(rac_willDeallocSignal)
    .subscribeNext(->(x) {
      refresh
    }.weak!)
  end

  def disableRefresh
    if @refreshDisposable
      @refreshDisposable.dispose
      @refreshDisposable = nil
    end
  end

  def promptForAccess
    accessSignal.subscribeCompleted(-> {})
  end

  def accessSignal
    RACSignal.createSignal(->(subscriber) {
      if _authorized?
        subscriber.sendNext(true)
        subscriber.sendCompleted
      else
        @store.requestAccessToEntityType(EKEntityTypeEvent, completion:->(_granted, _error) {
          RACScheduler.mainThreadScheduler.schedule(-> {
            resetStoredSelectedCalendars
            refresh
            subscriber.sendNext(_authorized?)
            subscriber.sendCompleted
          })
        })
      end
      nil
    }).subscribeOn(RACScheduler.mainThreadScheduler).deliverOn(RACScheduler.mainThreadScheduler)
  end

  def refresh
    RMX.assert_main_thread!
    self.status = _status
    self.granted = _authorized?
    if granted
      NSLog("[#{className}] refresh")
      resetSources
      loadEvents
    else
      self.events = []
    end
  end

  def selectedCalendarObjects
    RMX.assert_main_thread!
    set = NSMutableSet.new
    if granted
      calendars = @store.calendarsForEntityType(EKEntityTypeEvent).select do |calendarObject|
        @selectedCalendars.containsObject(calendarObject.calendarIdentifier)
      end
      set.addObjectsFromArray(calendars)
    end
    set
  end

  def selectedCalendarObjects=(calendarsSet)
    RMX.assert_main_thread!
    new_selected = NSMutableSet.new
    new_selected.addObjectsFromArray(calendarsSet.allObjects.map(&:calendarIdentifier))
    self.selectedCalendars = new_selected
    storeSelectedCalendars
    refresh
  end

  def newCalendarChooser
    RMX.assert_main_thread!
    controller = EKCalendarChooser.alloc.initWithSelectionStyle(EKCalendarChooserSelectionStyleMultiple, displayStyle:EKCalendarChooserDisplayAllCalendars, entityType:EKEntityTypeEvent, eventStore:PZOEventManager.shared.store)
    controller.hidesBottomBarWhenPushed = true
    controller.delegate = self
    controller.showsDoneButton = true
    controller.showsCancelButton = true
    controller.selectedCalendars = selectedCalendarObjects

    opts = {}

    # store if the controller was animated in
    controller.rac_signalForSelector('viewWillAppear:')
    .take(1)
    .subscribeNext(->(tuple) {
      opts[:animated] = tuple[0].boolValue
    })

    RACSignal.merge([
      rac_signalForSelector("calendarChooserDidCancel:"),
      rac_signalForSelector("calendarChooserDidFinish:")
    ])
    .take(1)
    .mapReplace(controller)
    .subscribeNext(->(c) {
      anim = (opts[:animated] || false)
      if c.presentingViewController
        c.dismissViewControllerAnimated(anim, completion:nil)
      elsif c.navigationController
        c.navigationController.popViewControllerAnimated(anim)
      end
    })

    controller
  end

  private

  def _authorized?
    _status == EKAuthorizationStatusAuthorized
  end

  def _status
    EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
  end

  def resetSources
    RMX.assert_main_thread!
    new_sources = []
    new_selected = NSMutableSet.new

    @store.reset
    @store.refreshSourcesIfNecessary
    store_sources = @store.sources

    if store_sources
      if stored = getStoredSelectedCalendars
        new_selected.setSet(stored)
      end
      store_sources.each do |source|
        calendars = source.calendarsForEntityType(EKEntityTypeEvent)
        if calendars.count > 0
          new_sources.addObject(source)
          unless stored
            new_selected.addObjectsFromArray(calendars.allObjects.map(&:calendarIdentifier))
          end
        end
      end
    end

    self.sources = new_sources
    self.selectedCalendars = new_selected
    storeSelectedCalendars
  end

  def resetStoredSelectedCalendars
    RMX.assert_main_thread!
    NSLog("[#{className}] resetStoredSelectedCalendars")
    NSUserDefaults.standardUserDefaults.removeObjectForKey(selectedCalendarsKey)
    NSUserDefaults.standardUserDefaults.synchronize
  end

  def getStoredSelectedCalendars
    RMX.assert_main_thread!
    if data = NSUserDefaults.standardUserDefaults.objectForKey(selectedCalendarsKey)
      if existing = NSKeyedUnarchiver.unarchiveObjectWithData(data) and existing.is_a?(NSSet)
        existing
      end
    end
  end

  def storeSelectedCalendars
    RMX.assert_main_thread!
    if @selectedCalendars
      NSUserDefaults.standardUserDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(@selectedCalendars), forKey:selectedCalendarsKey)
      NSUserDefaults.standardUserDefaults.synchronize
    end
  end

  def loadEvents
    RMX.assert_main_thread!
    _loadEvents
  end

  def _loadEvents
    new_events = []
    calendars = selectedCalendarObjects.allObjects

    if calendars.any?
      RMXRACHelper.schedulerWithHighPriority.schedule(-> {
        predicate = @store.predicateForEventsWithStartDate(firstDate, endDate:lastDate, calendars:calendars)
        new_events = (@store.eventsMatchingPredicate(predicate) || []).sortedArrayUsingSelector('compareStartDateWithEvent:')
        RACScheduler.mainThreadScheduler.schedule(-> {
          self.events = new_events
        })
      })
    end
  end

  # EKCalendarChooserDelegate

  def calendarChooserDidFinish(calendarChooser)
    self.selectedCalendarObjects = calendarChooser.selectedCalendars
  end

  def calendarChooserDidCancel(calendarChooser)
  end

end
