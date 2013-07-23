RMExtensions
-----------------

#### Extensions and helpers for dealing with various areas of rubymotion.

## Observation/KVO, Events

#### Make observations without needing to clean up/unobserve

Call from anywhere on anything:

```ruby
class MyViewController < UIViewController
  def viewDidLoad
    super.tap do
      rmext_observe(@model, "name") do |val|
        p "name is #{val}"
      end
      foo.rmext_on(:some_event) do |val|
        p "some_event called with #{val.inspect}"
      end
    end
  end
  def test_trigger
    foo.rmext_trigger(:some_event, "hello!")
  end
end
```

Differences from BW::KVO and BW::Reactor::Eventable:

- No need to include a module in the class you wish to use it on
- the observation happens on a proxy object
- KVO: The default is to observe and immediately fire the supplied callback
- KVO: The callback only takes one argument, the new value
- KVO: the object observing is not retained, and when it is deallocated, the observation
  will be removed automatically for you. there is typically no need to clean up manually


## Accessors

#### weak attr_accessors:

```ruby

class MyView < UIView
  rmext_weak_attr_accessor :delegate
end

class MyViewController < UIViewController
  def viewDidLoad
    super.tap do
      v = MyView.alloc.initWithFrame(CGRectZero)
      view.addSubview(v)
      v.delegate = self
    end
  end
end

```

## Queues

#### Wraps GCD:

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
