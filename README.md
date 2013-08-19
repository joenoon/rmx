RMExtensions
-----------------

#### Extensions and helpers for dealing with various areas of rubymotion and iOS.

## Equation-style AutoLayout Constraints 

AutoLayout is a great way to lay out views, but writing constraints manually is
confusing and verbose.

Using Apple's "Visual Format Language" ASCII-inspired
strings can improve things, but it has drawbacks:  **1)** It returns an array
of constraints.  This means if you plan on altering one of them later, or removing
one in particular, you would have to loop through all of the constraints, testing
each one to see if its the one you want.  **2)** The `options` argument adds additional
constraints.  For example, if you specify NSLayoutAttributeCenterY to a horizontal string,
an additional constraint will be added for each view to set their centerY's equal to each
other.  This compounds problem #1.  The chances you will get an error that the layout system
cannot satisfy your constraints is probably because of these "extra" constraints. **3)**
It can't handle complex constraints, so you end up needing to supplement it with
verbose low-level constraint creation anyway.

Apple makes note of how constraints can be thought of like a linear equation:

http://developer.apple.com/library/ios/documentation/AppKit/Reference/NSLayoutConstraint_Class/NSLayoutConstraint/NSLayoutConstraint.html

**Remember the formula:**

```ruby
view1.attr1 == view2.attr2 * multiplier + constant @ priority
```

**We can actually use this super-simple formula to write ALL of our constraints, simple OR complex!**

Once you get the hang of the formula and visualization of how the geometry works, it becomes easy to create complex layouts with little
effort.  And, in my opinion, its only slightly more verbose than the visual format language, but much clearer, and you only end up
with the exact constraints you want.

Available values for `attr1` and `attr2` are:

- left
- right
- top
- bottom
- leading
- trailing
- width
- height
- centerX
- centerY
- baseline

Available `relation` values are:

- ==
- <=
- >=

Available `priority` values are:

- required (1000 is the default)
- high (750)
- low (250)
- fit (50)
- or, you can use your own value between 1-1000


### Examples

Here is a real example.  The Layout instance is created just like the motion-layout gem.  `layout.view` sets the view
that will act as the 'superview' to the views set in `layout.subviews`.  Thats where the similarities end with
motion-layout.  With RMExtensions::Layout, there are two methods: `eq` and `eqs`, short for equation and equations.

- `layout.eq` takes one string, and returns *one constraint*
- `layout.eqs` takes one string, assumes multiple constraints are separated by newlines, and returns an *array of constraints*

```ruby
RMExtensions::Layout.new do |layout|
  layout.view view
  layout.subviews({
    "calendar" => calendarView,
    "table" => tableView,
    "shadow" => line
  })

  layout.eqs %Q{
    calendar.left == 0
    calendar.right == 0
    table.left == 7
    table.right == -7
    shadow.left == 0
    shadow.right == 0

    calendar.top == 0
    table.top == calendar.bottom
    table.bottom == 0
    shadow.top == table.top
  }

  @calendar_height_constraint = layout.eq "calendar.height == 0"
end
```

Above, **calendar.left == 0** is short for **calendar.left == view.left * 1.0 + 0 @ 1000**.  If no view2 is given, the superview ('view') is assumed.
If no multiplier is given, 1.0 is assumed.  If no constant is given, 0 is assumed.  If no priority is given, "required" (1000) is assumed.
The last constraint is created separately and stored in @calendar_height_constraint, because I want to be able to change the calendar's height
any time I want.

Here is another example:

```ruby
RMExtensions::Layout.new do |layout|
  layout.view self
  layout.subviews({
    "timeLabel" => @timeLabel,
    "titleLabel" => @titleLabel,
    "trackingImage" => @trackingImage,
    "inOutStatusInImage" => @inOutStatusInImage,
    "inOutStatusOutImage" => @inOutStatusOutImage,
    "plannerImage" => @plannerImage,
    "shareButton" => @shareButton,
    "cancelledLabel" => @cancelledLabel,
    "unreadImage" => @unreadImage
  })
  
  layout.eqs %Q{
    unreadImage.left == 6
    unreadImage.top == 6
    plannerImage.left == 14
    plannerImage.centerY == 0
    plannerImage.width == 30
    plannerImage.height == 30
    trackingImage.left == timeLabel.right + 5
    inOutStatusOutImage.left == trackingImage.right + 5
    inOutStatusInImage.left == inOutStatusOutImage.right + 5
    timeLabel.left == plannerImage.right + 5
    timeLabel.baseline == plannerImage.bottom + 1
    trackingImage.centerY == timeLabel.centerY
    inOutStatusOutImage.centerY == timeLabel.centerY
    inOutStatusInImage.centerY == timeLabel.centerY
    titleLabel.left == cancelledLabel.right
    cancelledLabel.left == plannerImage.right + 5
    titleLabel.top == plannerImage.top - 4
    cancelledLabel.centerY == titleLabel.centerY
    shareButton.right == -10
    shareButton.centerY == 0
    titleLabel.resistH == low
    shareButton.left >= titleLabel.right + 5
    timeLabel.resistH == low
    shareButton.left >= inOutStatusInImage.right + 5
  }

end
```

Keep in mind none of these lines are using the multiplier, and thats OK.  I've only needed it on one constraint in my entire app so far,
so don't think its odd if you can't find a use for it.

There are two special cases at the moment.  **titleLabel.resistH == low** is not a "real" constraint.  Its a shortcut to
`setContentCompressionResistancePriority`, and since its common when dealing with autolayout, its nice to include it
in our layout code.  The same is done for `setContentHuggingPriority`.  The full list of "special cases" at the moment:

- view1.resistH == priority
- view1.resistV == priority
- view1.hugH == priority
- view1.hugV == priority

"priority" can be one of the values listed earlier, or your own number between 1-1000.

### Debugging constraints

- You can include a **?** on any line, and debug output will be printed when that constraint is built:

```ruby
layout.eqs %Q{
  label.left == photo.right + 5 ?
}
```

- Since layout.eqs allows you to write many constraints in one string, and sometimes its nice to
keep comments next to constraints, **comments are allowed**:

```ruby
layout.eqs %Q{
  commentsCount.width == likesCount.width @ low # the widths of the labels prefer to be the same
}
```

### Things to remember

- Remember you usually want negative constants for right and bottom.  For example: label.right == -10 means "label's right should be 10 away from the right side of the superview".  But if you accidentally said label.right == 10, you would have created "label's right should be 10 PAST the right side of the superview".  It may require you to adjust your thinking.

- The formula is just shorthand for `constraintWithItem:attribute:relatedBy:toItem:attribute:multiplier:constant:`.  You should **really** read up on constraints and
understand this method, to fully understand the power and simplicity the shorthand formula gives you.








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
