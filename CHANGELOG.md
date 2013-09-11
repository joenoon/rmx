## 0.1.9

[Commit history](https://github.com/joenoon/rm-extensions/compare/v0.1.8...v0.1.9)

* Util: Added #rmext_ivar, which is a shortcut to instance_variable_get/instance_variable_set
* Layout: Added #reopen to yield the instance to a block for further processing
* Layout: Added an internal "constraint table" to keep track of normalized equations and
  NSLayoutConstraint objects.  equations can now be modified simply by re-applying the same
  equation with a different constant.
* Layout: Added #xeq to remove a constraint by equation
* Layout: Added #remove(constraint(s)) to remove NSLayoutConstraint obects from the view
  and also from the internal constraint table.

## 0.1.8

[Commit history](https://github.com/joenoon/rm-extensions/compare/v0.1.7...v0.1.8)

* Added RMExtensions::Layout#clear! which is a shortcut to view.removeConstraints(view.constraints).
  It must be called after the `view` is set.
* Added 'max' as a valid priority shortcut, since it reads better than 'required' in many cases.
* Comments are now allowed on a line by themselves inside a `eqs` string, to make for easier commenting,
  or to easily comment out an equation.
* Added a special `last_visible` view identifier which can be used instead of an actual view name
  inside an equation.  It will refer to the last view a constraint was applied to that was not hidden.
  This can be used to more easily lay out constraints when some views should not be anchored against.
  For example, you have 3 labels, A, B, and C, that you want stacked vertically:
    A.top == 0
    B.top == A.bottom + 5
    C.top == B.bottom + 5
  If B is hidden, there would be 10px in between A and C.  Instead, you can let RMExtensions::Layout handle
  this for you:
    A.top == 0                        # last_visible is set to A
    B.top == last_visible.bottom + 5  # B is hidden, so last_visible remains A
    C.top == last_visible.bottom + 5  # C now aligns to the bottom of A
  It is usually easier and cleaner to build all possible views and mark some hidden than it is to have
  many if/else view creation and constraint construction specific to what should be displayed.
