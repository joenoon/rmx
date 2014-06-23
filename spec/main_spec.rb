describe "Equation-style AutoLayout Constraints" do

  def self.test_constraint_equation(c1_str, optional_desc=nil, &block)
    it "#{optional_desc || c1_str}" do
      c1 = @layout.eq c1_str
      c2 = block.call
      c1.priority.should == c2.priority
      c1.firstItem.should == c2.firstItem
      c1.firstAttribute.should == c2.firstAttribute
      c1.relation.should == c2.relation
      c1.secondItem.should == c2.secondItem
      c1.secondAttribute.should == c2.secondAttribute
      c1.multiplier.should == c2.multiplier
      c1.constant.should == c2.constant
    end
  end

  before do
    @view = UIView.new
    @label1 = UILabel.new
    @label2 = UILabel.new
    @layout = RMX::Layout.new
    @layout.view @view
    @layout.subviews({
      "label1" => @label1,
      "label2" => @label2
    })
  end

  test_constraint_equation("label1.left == 0") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeLeft,
    multiplier:1.0,
      constant:0)
  end

  test_constraint_equation("label1.left == 8") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeLeft,
    multiplier:1.0,
      constant:8)
  end

  test_constraint_equation("label1.right == -20") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeRight,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeRight,
    multiplier:1.0,
      constant:-20)
  end

  test_constraint_equation("label1.top == 0") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeTop,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeTop,
    multiplier:1.0,
      constant:0)
  end

  test_constraint_equation("label1.bottom == -36") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeBottom,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeBottom,
    multiplier:1.0,
      constant:-36)
  end

  test_constraint_equation("label1.height == 1") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeHeight,
     relatedBy:NSLayoutRelationEqual,
        toItem:nil,
     attribute:NSLayoutAttributeNotAnAttribute,
    multiplier:1.0,
      constant:1)
  end

  test_constraint_equation("label1.centerX == 0") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeCenterX,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeCenterX,
    multiplier:1.0,
      constant:0)
  end

  test_constraint_equation("label1.width == 1.5") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeWidth,
     relatedBy:NSLayoutRelationEqual,
        toItem:nil,
     attribute:NSLayoutAttributeNotAnAttribute,
    multiplier:1.0,
      constant:1.5)
  end

  test_constraint_equation("label1.left >= 6") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationGreaterThanOrEqual,
        toItem:@view,
     attribute:NSLayoutAttributeLeft,
    multiplier:1.0,
      constant:6)
  end

  test_constraint_equation("label1.width == 0 @ low # prefer box hugs content") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeWidth,
     relatedBy:NSLayoutRelationEqual,
        toItem:nil,
     attribute:NSLayoutAttributeNotAnAttribute,
    multiplier:1.0,
      constant:0).tap { |x| x.priority = UILayoutPriorityDefaultLow }
  end

  test_constraint_equation("label1.left == 24 @ low # this button prefers to hug the left") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeLeft,
    multiplier:1.0,
      constant:24).tap { |x| x.priority = UILayoutPriorityDefaultLow }
  end

  test_constraint_equation("label1.top == view.top + 8") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeTop,
     relatedBy:NSLayoutRelationEqual,
        toItem:@view,
     attribute:NSLayoutAttributeTop,
    multiplier:1.0,
      constant:8)
  end

  test_constraint_equation("label1.left == label2.left * 0.5 - 5") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeLeft,
    multiplier:0.5,
      constant:-5)
  end

  test_constraint_equation("label1.top == label2.top + 5") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeTop,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeTop,
    multiplier:1.0,
      constant:5)
  end

  test_constraint_equation("label1.top == label2.bottom") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeTop,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeBottom,
    multiplier:1.0,
      constant:0)
  end

  test_constraint_equation("label1.width == label2.width @ low # the widths of the labels prefer to be the same") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeWidth,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeWidth,
    multiplier:1.0,
      constant:0).tap { |x| x.priority = UILayoutPriorityDefaultLow }
  end

  test_constraint_equation("label1.left == label2.right + 20") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeRight,
    multiplier:1.0,
      constant:20)
  end

  test_constraint_equation("label1.centerY == label2.centerY") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeCenterY,
     relatedBy:NSLayoutRelationEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeCenterY,
    multiplier:1.0,
      constant:0)
  end

  test_constraint_equation("label1.left >= label2.right + 6") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeLeft,
     relatedBy:NSLayoutRelationGreaterThanOrEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeRight,
    multiplier:1.0,
      constant:6)
  end

  test_constraint_equation("label1.right <= view.right - 8") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeRight,
     relatedBy:NSLayoutRelationLessThanOrEqual,
        toItem:@view,
     attribute:NSLayoutAttributeRight,
    multiplier:1.0,
      constant:-8)
  end

  test_constraint_equation("label1.right <= label2.left - 10") do
    NSLayoutConstraint.constraintWithItem(@label1,
     attribute:NSLayoutAttributeRight,
     relatedBy:NSLayoutRelationLessThanOrEqual,
        toItem:@label2,
     attribute:NSLayoutAttributeLeft,
    multiplier:1.0,
      constant:-10)
  end

end
