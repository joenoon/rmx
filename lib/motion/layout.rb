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

    RELATED_BY_LOOKUP = {
      "<=" => NSLayoutRelationLessThanOrEqual,
      "==" => NSLayoutRelationEqual,
      ">=" => NSLayoutRelationGreaterThanOrEqual
    }

    PRIORITY_LOOKUP = {
      "required" => UILayoutPriorityRequired, # = 1000
      "high" => UILayoutPriorityDefaultHigh, # = 750
      "low" => UILayoutPriorityDefaultLow, # = 250
      "fit" => UILayoutPriorityFittingSizeLevel # = 50
    }

    AXIS_LOOKUP = {
      "h" => UILayoutConstraintAxisHorizontal,
      "v" => UILayoutConstraintAxisVertical
    }

    def initialize
      if block_given?
        yield self
      end
    end

    def view(view=nil)
      if view
        @view = view
      end
      @view
    end

    def subviews(subviews=nil)
      if subviews
        @subviews = subviews
        @subviews.values.each do |subview|
          subview.translatesAutoresizingMaskIntoConstraints = false
          @view.addSubview(subview)
        end
      end
      @subviews
    end

    def eqs(str, debug=false)
      str.split("\n").map(&:strip).select { |x| !x.empty? }.map do |line|
        eq(line, debug)
      end
    end

    def eq?(str)
      eq(str, true)
    end

    # Constraints are of the form "view1.attr1 <relation> view2.attr2 * multiplier + constant @ priority"
    def eq(str, debug=false)
      item = nil
      item_attribute = nil
      related_by = nil
      to_item = nil
      to_item_attribute = nil
      multiplier = nil
      constant = nil
      
      parts = str.split(" ").select { |x| !x.empty? }

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

      # look for multipler
      if idx = parts.index("*")
        multipler = parts[idx + 1]
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

      debug_hash = nil

      if debug
        debug_hash = {
          :item => item,
          :item_attribute => item_attribute,
          :related_by => related_by,
          :to_item => to_item,
          :to_item_attribute => to_item_attribute,
          :multiplier => multiplier,
          :constant => constant,
          :priority => priority
        }
      end

      # normalize

      res_item = item == "view" ? @view : @subviews[item]
      res_item_attribute = ATTRIBUTE_LOOKUP[item_attribute]
      res_related_by = RELATED_BY_LOOKUP[related_by]
      res_to_item = if to_item
        to_item == "view" ? @view : @subviews[to_item]
      end
      res_to_item_attribute = ATTRIBUTE_LOOKUP[to_item_attribute]
      res_multiplier = multiplier ? Float(multiplier) : 1.0
      res_constant = constant ? Float(PRIORITY_LOOKUP[constant] || constant) : 0.0
      res_priority = priority ? Integer(PRIORITY_LOOKUP[priority] || priority) : nil

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

      errors = []
      errors.push("Invalid view1: #{item}") unless res_item
      errors.push("Invalid attr1: #{item_attribute}") unless res_item_attribute
      errors.push("Invalid relatedBy: #{related_by}") unless res_related_by
      errors.push("Invalid view2: #{to_item}") if to_item && !res_to_item
      errors.push("Invalid attr2: #{to_item_attribute}") unless res_to_item_attribute

      if errors.size > 0 || debug
        puts "======================== constraint debug ========================"
        puts "given:"
        puts "  #{str}"
        puts "interpreted:"
        puts "  item:                #{item}"
        puts "  item_attribute:      #{item_attribute}"
        puts "  related_by:          #{related_by}"
        puts "  to_item:             #{to_item}"
        puts "  to_item_attribute:   #{to_item_attribute}"
        puts "  multiplier:          #{multiplier}"
        puts "  constant:            #{constant}"
        puts "  priority:            #{priority}"
      end

      if errors.size > 0
        raise(errors.join(", "))
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
        puts "implemented:"
        puts "  #{constraint.description}"
      end

      @view.addConstraint(constraint)
      constraint
    end

  end
end
