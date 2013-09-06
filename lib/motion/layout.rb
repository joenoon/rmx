module RMExtensions
  class Layout

    ATTRIBUTE_LOOKUP = {
      "left" => NSLayoutAttributeLeft,
      "right" => NSLayoutAttributeRight,
      "top" => NSLayoutAttributeTop,
      "bottom" => NSLayoutAttributeBottom,
      "leading" => NSLayoutAttributeLeading,
      "trailing" => NSLayoutAttributeTrailing,
      "width" => NSLayoutAttributeWidth,
      "height" => NSLayoutAttributeHeight,
      "centerX" => NSLayoutAttributeCenterX,
      "centerY" => NSLayoutAttributeCenterY,
      "baseline" => NSLayoutAttributeBaseline,
      nil => NSLayoutAttributeNotAnAttribute
    }

    ATTRIBUTE_LOOKUP_INVERSE = ATTRIBUTE_LOOKUP.invert

    RELATED_BY_LOOKUP = {
      "<=" => NSLayoutRelationLessThanOrEqual,
      "==" => NSLayoutRelationEqual,
      ">=" => NSLayoutRelationGreaterThanOrEqual
    }

    RELATED_BY_LOOKUP_INVERSE = RELATED_BY_LOOKUP.invert

    PRIORITY_LOOKUP = {
      "max" => UILayoutPriorityRequired, # = 1000
      "required" => UILayoutPriorityRequired, # = 1000
      "high" => UILayoutPriorityDefaultHigh, # = 750
      "low" => UILayoutPriorityDefaultLow, # = 250
      "fit" => UILayoutPriorityFittingSizeLevel # = 50
    }

    PRIORITY_LOOKUP_INVERSE = PRIORITY_LOOKUP.invert

    AXIS_LOOKUP = {
      "h" => UILayoutConstraintAxisHorizontal,
      "v" => UILayoutConstraintAxisVertical
    }

    def initialize
      @visible_items = []
      if block_given?
        yield self
      end
    end

    def clear!
      @view.removeConstraints(@view.constraints)
    end

    def view(view)
      @view = view
    end

    def view=(v)
      view(v)
    end

    def subviews(subviews)
      @subviews = subviews
      @subviews.values.each do |subview|
        subview.translatesAutoresizingMaskIntoConstraints = false
        @view.addSubview(subview)
      end
      @subviews
    end

    def subviews=(views)
      subviews(views)
    end

    def eqs(str)
      str.split("\n").map(&:strip).select { |x| !x.empty? }.map do |line|
        eq(line)
      end
    end

    # Constraints are of the form "view1.attr1 <relation> view2.attr2 * multiplier + constant @ priority"
    def eq(str)
      parts = str.split("#", 2).first.split(" ").select { |x| !x.empty? }
      return if parts.empty?

      item = nil
      item_attribute = nil
      related_by = nil
      to_item = nil
      to_item_attribute = nil
      multiplier = 1.0
      constant = 0.0
      
      debug = parts.delete("?")

      # first part should always be view1.attr1
      part = parts.shift
      item, item_attribute = part.split(".", 2)

      # second part should always be relation
      related_by = parts.shift

      # now things get more complicated

      # look for priority
      if idx = parts.index("@")
        priority = parts[idx + 1]
        parts.delete_at(idx)
        parts.delete_at(idx)
      end

      # look for negative or positive constant
      if idx = parts.index("-")
        constant = "-#{parts[idx + 1]}"
        parts.delete_at(idx)
        parts.delete_at(idx)
      elsif idx = parts.index("+")
        constant = parts[idx + 1]
        parts.delete_at(idx)
        parts.delete_at(idx)
      end

      # look for multiplier
      if idx = parts.index("*")
        multiplier = parts[idx + 1]
        parts.delete_at(idx)
        parts.delete_at(idx)
      end

      # now we need to_item, to_item_attribute

      if part = parts.shift
        # if part includes a . it could be either view2.attr2 or a float like 10.5
        l, r = part.split(".", 2)
        if !r || (r && r =~ /\d/)
          # assume a solo constant was on the right side
          constant = part
        else
          # assume view2.attr2
          to_item, to_item_attribute = l, r
        end
      end

      # if we dont have to_item and the item_attribute is something that requires a to_item, then
      # assume superview
      if !to_item
        unless item_attribute == "height" || item_attribute == "width"
          to_item = "view"
          to_item_attribute = item_attribute
        end
      end

      # normalize

      if item == "last_visible"
        item = @visible_items.first || "view"
      end

      res_item = view_for_item(item)
      res_constant = Float(PRIORITY_LOOKUP[constant] || constant)

      if res_item
        case item_attribute
        when "resistH"
          return res_item.setContentCompressionResistancePriority(res_constant, forAxis:UILayoutConstraintAxisHorizontal)
        when "resistV"
          return res_item.setContentCompressionResistancePriority(res_constant, forAxis:UILayoutConstraintAxisVertical)
        when "hugH"
          return res_item.setContentHuggingPriority(res_constant, forAxis:UILayoutConstraintAxisHorizontal)
        when "hugV"
          return res_item.setContentHuggingPriority(res_constant, forAxis:UILayoutConstraintAxisVertical)
        end
      end

      if to_item == "last_visible"
        to_item = @visible_items.detect { |x| x != item } || "view"
      end

      res_item_attribute = ATTRIBUTE_LOOKUP[item_attribute]
      res_related_by = RELATED_BY_LOOKUP[related_by]
      res_to_item = to_item ? view_for_item(to_item) : nil
      res_to_item_attribute = ATTRIBUTE_LOOKUP[to_item_attribute]
      res_multiplier = Float(multiplier)
      res_priority = priority ? Integer(PRIORITY_LOOKUP[priority] || priority) : nil

      errors = []
      errors.push("Invalid view1: #{item}") unless res_item
      errors.push("Invalid attr1: #{item_attribute}") unless res_item_attribute
      errors.push("Invalid relatedBy: #{related_by}") unless res_related_by
      errors.push("Invalid view2: #{to_item}") if to_item && !res_to_item
      errors.push("Invalid attr2: #{to_item_attribute}") unless res_to_item_attribute

      if errors.size > 0 || debug
        p "======================== constraint debug ========================"
        p "given:"
        p "  #{str}"
        p "interpreted:"
        p "  item:                #{item}"
        p "  item_attribute:      #{item_attribute}"
        p "  related_by:          #{related_by}"
        p "  to_item:             #{to_item}"
        p "  to_item_attribute:   #{to_item_attribute}"
        p "  multiplier:          #{multiplier}"
        p "  constant:            #{constant}"
        p "  priority:            #{priority || "required"}"
      end

      if errors.size > 0
        raise(errors.join(", "))
      end

      unless res_item.hidden?
        @visible_items.unshift(item)
      end

      constraint = NSLayoutConstraint.constraintWithItem(res_item,
         attribute:res_item_attribute,
         relatedBy:res_related_by,
            toItem:res_to_item,
         attribute:res_to_item_attribute,
        multiplier:res_multiplier,
          constant:res_constant)
      if res_priority
        constraint.priority = res_priority
      end

      if debug
        p "implemented:"
        p "  #{constraint.description}"
      end

      @view.addConstraint(constraint)
      constraint
    end

    def describe(constraint)
      subviews_inverse = subviews.invert
      item = subviews_inverse[constraint.firstItem]
      item_attribute = ATTRIBUTE_LOOKUP_INVERSE[constraint.firstAttribute]
      related_by = RELATED_BY_LOOKUP_INVERSE[constraint.relation]
      to_item = subviews_inverse[constraint.secondItem]
      to_item_attribute = ATTRIBUTE_LOOKUP_INVERSE[constraint.secondAttribute]
      multiplier = constraint.multiplier
      constant = constraint.constant
      priority = PRIORITY_LOOKUP_INVERSE[constraint.priority] || constraint.priority
      "#{item}.#{item_attribute} #{related_by} #{to_item}.#{to_item_attribute} * #{multiplier} + #{constant} @ #{priority}"
    end

    private

    def view_for_item(item)
      if item == "view"
        @view
      elsif v = (@subviews && @subviews[item])
        v
      end
    end

  end
end
