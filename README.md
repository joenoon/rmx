RMExtensions
-----------------

#### Extensions and helpers for dealing with various areas of rubymotion.

## Observation

#### Make observations without needing to clean up/unobserve

Call from anywhere on anything:

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

Differences from BW::KVO:

- No need to include a module in the class you wish to use it on
- The default is to observe and immediately fire the supplied callback
- The callback only takes one argument, the new value
- the object observing is not retained, and when it is deallocated, the observation
  will be removed automatically for you. there is typically no need to clean up
  and unobserve in viewWillDisappear, or similar.
- the observation actually happens on an unretained proxy object


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

Installation
-----------------

Add this line to your application's Gemfile:

    gem 'rm-extensions'

And then execute:

    $ bundle

* Currently depends on bubblewrap (for BW::KVO).

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
