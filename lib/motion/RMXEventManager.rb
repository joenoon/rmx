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
#   instantly when called, app launch, returning from background, event store changes
#
# `disableRefresh` will stop listening for events that would trigger a refresh
#
# `promptForAccess` should be called when you are comfortable with displaying the permissions alert
# to obtain access to calendars.  If access is already granted, this does nothing. Until
# access is granted, `events` will be an empty array.
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

  attr_accessor :accessible, :events, :sources, :selectedCalendars, :calendar, :store

  attr_reader :refreshSignal, :eventsSignal, :storeChangedSignal

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
    @accessible = EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) == EKAuthorizationStatusAuthorized
    @sources = []
    @selectedCalendars = NSMutableSet.new

    @storeChangedSignal = NSNotificationCenter.defaultCenter.rac_addObserverForName(EKEventStoreChangedNotification, object:@store).takeUntil(rac_willDeallocSignal)

    @refreshSignal = RACSignal.merge([
      RACSignal.return(true),
      RMX.rac_appDidFinishLaunchingNotification,
      RMX.rac_appDidBecomeActiveFromBackground,
      @storeChangedSignal
    ])
    .bufferWithTime(0.5, onScheduler:RACScheduler.mainThreadScheduler)

    @eventsSignal = RMX(self).racObserve(self, "events")
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
    }.rmx_weak!)
  end

  def disableRefresh
    if @refreshDisposable
      @refreshDisposable.dispose
      @refreshDisposable = nil
    end
  end

  def promptForAccess
    if EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) != EKAuthorizationStatusAuthorized
      @store.requestAccessToEntityType(EKEntityTypeEvent, completion:->(granted,error) {
        RACScheduler.mainThreadScheduler.schedule(-> {
          self.accessible = granted
          if accessible
            self.events = []
            @store.reset
            refresh
          end
        })
      })
    end
  end

  def refresh
    resetSources
    loadEvents
  end

  def selectedCalendarObjects
    calendars = @store.calendarsForEntityType(EKEntityTypeEvent).select do |calendarObject|
      @selectedCalendars.containsObject(calendarObject.calendarIdentifier)
    end
    set = NSMutableSet.new
    set.addObjectsFromArray(calendars)
    set
  end

  def selectedCalendarObjects=(calendarsSet)
    new_selected = NSMutableSet.new
    new_selected.addObjectsFromArray(calendarsSet.allObjects.map(&:calendarIdentifier))
    self.selectedCalendars = new_selected
    storeSelectedCalendars
    refresh
  end

  def newCalendarChooser
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
      RMXViewControllerPresentation.dismiss({
        :view_controller => c,
        :animated => (opts[:animated] || false),
        :completion => nil
      })
    })

    controller
  end

  private

  def resetSources
    new_sources = []
    new_selected = NSMutableSet.new
    if stored = getStoredSelectedCalendars
      new_selected.setSet(stored)
    end

    if store_sources = @store.sources
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

  def getStoredSelectedCalendars
    if data = NSUserDefaults.standardUserDefaults.objectForKey(selectedCalendarsKey)
      if existing = NSKeyedUnarchiver.unarchiveObjectWithData(data) and existing.is_a?(NSSet)
        existing
      end
    end
  end

  def storeSelectedCalendars
    if @selectedCalendars
      NSUserDefaults.standardUserDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(@selectedCalendars), forKey:selectedCalendarsKey)
      NSUserDefaults.standardUserDefaults.synchronize
    end
  end

  def loadEvents
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
