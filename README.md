RMExtensions
-----------------

#### Extensions and helpers for dealing with various areas of rubymotion.

## Observation

#### Make observations without needing to clean up/unobserve, and avoid retain-cycles

Call from anywhere on anything without prior inclusion of BW::KVO:

```ruby
class MyViewController < UIViewController
  def viewDidLoad
    super.tap do
      rmext_observe(@model, "name") do |val|
        p "name is #{val}"
      end
    end
  end
end
```

Under the hood this piggy-backs on Bubblewrap's KVO implementation.

Differences:

- No need to include BW::KVO anywhere
- The default is to observe and immediately fire the supplied callback
- The callback only takes one argument, the new value
- the object observing is not retained, and when it is deallocated, the observation
  will be removed automatically for you. there is typically no need to clean up
  and unobserve in viewWillDisappear, or similar.
- because the observation actually happens on an unretained proxy object, the real
  object shouldnt incur any retain cycles.

Similarities:

- the object observed is retained


## Accessors

#### weak attr_accessors when you need to avoid retain-cycles:

```ruby

class MyView < UIView
  rmext_weak_attr_accessor :delegate
end

class MyViewController < UIViewController
  def viewDidLoad
    super.tap do
      v = MyView.alloc.initWithFrame(CGRectZero)
      view.addSubview(v)
      # if delegate was a normal attr_accessor, this controller could never be deallocated
      v.delegate = self
    end
  end
end

```

## Deallocation

#### watch for an object to deallocate, and execute a callback:

```ruby
def add_view_controller
  controller = UIViewController.alloc.init
  controller.rmext_on_dealloc(&test_dealloc_proc)
  navigationController.pushViewController(controller, animated: true)
end

def test_dealloc_proc
  proc { |x| p "it deallocated!" }
end

# now you can verify the controller gets deallocated by calling #add_view_controller
# and then popping it off the navigationController

# you should be careful not to create the block inline, since it could easily create a retain cycle
# depending what other objects are in scope.
```
## Queues

#### Wraps GCD to avoid complier issues with blocks and also ensures the block passed is retained until executed on the queue:

```ruby
# note +i+ will appear in order, and the thread will never change (main)
100.times do |i|
  rmext_on_main_q do
    p "i: #{i} thread: #{NSThread.currentThread}"
  end
end

# note +i+ will appear in order, and the thread will change
100.times do |i|
  rmext_on_serial_q("testing") do
    p "i: #{i} thread: #{NSThread.currentThread}"
  end
end

# note +i+ will sometimes appear out of order, and the thread will change
100.times do |i|
  rmext_on_concurrent_q("testing") do
    p "i: #{i} thread: #{NSThread.currentThread}"
  end
end
```

## Context

#### break through local variable scope bugs, where using instance variables would mean your method is not re-entrant. retain objects through asynchronous operations.

##### rmext_context

```ruby
# yields an object you can treat like an openstruct.  you can get/set any property
# on it.  useful for scope issues where local variables wont work, and where instance
# variables would clutter the object and not be re-entrant.

# Consider this example:

button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
button.when_tapped do
  button.setTitle("Tapped", forState:UIControlStateNormal)
end
view.addSubview(button)

# when button is tapped, you will get this:
# >> Program received signal EXC_BAD_ACCESS, Could not access memory.

# Workaround using +rmext_context+:

rmext_context do |x|
  x.button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
  x.button.when_tapped do
    x.button.setTitle("Tapped", forState:UIControlStateNormal)
  end
  view.addSubview(x.button)
end

# when button is tapped, it works.

# a note about the different use cases for +rmext_context+ and +rmext_retained_context+,
# because its important to understand when to use which, and what different purposes they
# are for:

# +rmext_context+ is used here instead of +rmext_retained_context+ because:

# 1. the button is already going to be retained by the view its added to, so
#    there is no need for us to retain it explicitly.
# 2. there would be no clear way to eventually "detach" it, since the button
#    could be clicked any number of times.
```

##### rmext_retained_context

```ruby
# like +rmext_context+ but the context is retained (as well as anything set on it) until you
# explicitly call +detach!+ or +detach_on_death_of+ and that object is deallocated.  prevents
# deallocation of objects until you are done with them, for example  through asynchronous
# operations.

# also has a useful shortcut for beginBackgroundTaskWithExpirationHandler/endBackgroundTask
# via +begin_background!+.  when you call +detach!+ the background task will be ended for you
# as well.

# use this over +rmext_context+ when you have a scenario when eventually you know everything
# is complete, and can call +detach!+.  for example, an operation that makes an http request,
# uses the result to call another operation on a specific queue, and is finally considered
# "finished" at some point in time in the future.  there is a definitive "end", at some point
# in the future.

# example:

rmext_retained_context do |x|
  rmext_on_serial_q("my_serial_q") do
    some_async_http_request do |results1|
      x.results1 = results1
      rmext_on_serial_q("my_serial_q") do
        some_other_async_http_request do |results2|
          x.results2 = results2
          rmext_on_main_q do
            p "results1", x.results1
            p "results2", x.results2
            x.detach!
          end
        end
      end
    end
  end
end
```

## Retention

#### A type of retain/release that just uses rubymotion's memory-management rules instead of calling the native retain/release:

```ruby
class MyViewController < UITableViewController
  
  # note here, if the view controller is deallocated during the http request (someone hits Back, etc),
  # and then the http request finishes, and you try to call tableView.reloadData, it will be a
  # EXC_BAD_ACCESS:
  def fetch_unsafe
    remote_http_request do |result|
      @models = []
      tableView.reloadData
    end
  end

  # ensure self stay around long enough for the block to be called
  def fetch
    rmext_retain!
    remote_http_request do |result|
      @models = []
      tableView.reloadData
      rmext_detach!
    end
  end

end
```

Installation
-----------------

Add this line to your application's Gemfile:

    gem 'rm-extensions'

And then execute:

    $ bundle

* Currently depends on bubblewrap (for BW::KVO).
* AssociatedObject objc runtime taken from BlocksKit, modified to work with rubymotion.

Contributing
-----------------

If you have a better way to accomplish anything this library is doing, please share!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

License
-----------------

Please see [LICENSE](https://github.com/joenoon/rm-extensions/blob/master/LICENSE.txt) for licensing details.


Author
-----------------

Joe Noon, [joenoon](https://github.com/joenoon)
