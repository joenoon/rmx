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
      "med" => 500,
      "low" => UILayoutPriorityDefaultLow, # = 250
      "fit" => UILayoutPriorityFittingSizeLevel # = 50
    }

    PRIORITY_LOOKUP_INVERSE = PRIORITY_LOOKUP.invert

    AXIS_LOOKUP = {
      "h" => UILayoutConstraintAxisHorizontal,
      "v" => UILayoutConstraintAxisVertical
    }

    # keeps track of views that are not #hidden? as constraints are built, so the
    # special `last_visible` view name can be used in equations.
    # exposed for advanced layout needs.
    attr_accessor :visible_items

    # Example:
    # RMExtensions::Layout.new do |layout|
    #   ...
    # end
    def initialize(&block)
      @block_owner = block.owner if block
      @visible_items = []
      @constraints = {}
      unless block.nil?
        block.call(self)
        block = nil
      end
    end

    # reopens the RMExtensions::Layout instance for additional processing, ex:
    #   @layout.reopen do |layout|
    #     ...
    #   end
    # note: you would need to store your instance somewhere on creation to be able to reopen it later, ex:
    #   @layout = RMExtensions::Layout.new do |layout|
    #     ...
    #   end
    def reopen
      if block_given?
        yield self
      end
      self
    end

    def clear!
      @view.removeConstraints(@view.constraints)
    end

    def remove(constraint)
      constraints = [ constraint ].flatten.compact
      @view.removeConstraints(constraints)
      @constraints.keys.each do |key|
        @constraints.delete(key) if constraints.include?(@constraints.fetch(key))
      end
      true
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

    # takes a string one or more equations separated by newlines and
    # processes each.  returns an array of constraints
    def eqs(str)
      str.split("\n").map(&:strip).select { |x| !x.empty? }.map do |line|
        eq(line)
      end.compact
    end

    # Constraints are of the form "view1.attr1 <relation> view2.attr2 * multiplier + constant @ priority"
    # processes one equation string
    def eq(str, remove=false)
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

      internal_ident = "#{item}.#{item_attribute} #{related_by} #{to_item}.#{to_item_attribute} * #{multiplier} @ #{priority}"

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
        p "  internal_ident:      #{internal_ident}"
      end

      if errors.size > 0
        raise(errors.join(", "))
      end

      unless res_item.hidden?
        @visible_items.unshift(item)
      end

      if remove
        if constraint = @constraints[internal_ident]
          if debug
            p "status:"
            p "  existing (for removal)"
          end
          @view.removeConstraint(constraint)
        else
          raise "RMExtensions::Layout could not find constraint to remove for internal_ident: `#{internal_ident}` (note: this is an internal representation of the constraint, not the exact string given).  Make sure the constraint was created first."
        end
      elsif constraint = @constraints[internal_ident]
        if debug
          p "status:"
          p "  existing (for modification)"
        end
        constraint.constant = res_constant
      else
        constraint = NSLayoutConstraint.constraintWithItem(res_item,
           attribute:res_item_attribute,
           relatedBy:res_related_by,
              toItem:res_to_item,
           attribute:res_to_item_attribute,
          multiplier:res_multiplier,
            constant:res_constant)
        if debug
          p "status:"
          p "  created"
        end
        @constraints[internal_ident] = constraint
        if res_priority
          constraint.priority = res_priority
        end
        @view.addConstraint(constraint)
      end

      if debug
        p "implemented:"
        p "  #{constraint.description}"
      end

      constraint
    end

    # removes the constraint matching equation string.  constant is not considered.
    # if no matching constraint is found, it will raise an exception.
    def xeq(str)
      eq(str, true)
    end

    def describe_constraint(constraint)
      self.class.describe_constraint(@subviews, constraint)
    end

    def describe_view
      self.class.describe_view(@subviews, @view)
    end

    # transforms an NSLayoutConstraint into a string.  this string is for debugging and produces
    # a verbose translation.  its not meant to be copied directly as an equation.
    # pass the subviews hash just as you would to Layout#subviews=, followed by the NSLayoutConstraint
    def self.describe_constraint(subviews, constraint)
      subviews_inverse = subviews.invert
      item = subviews_inverse[constraint.firstItem] || "view"
      item_attribute = ATTRIBUTE_LOOKUP_INVERSE[constraint.firstAttribute]
      related_by = RELATED_BY_LOOKUP_INVERSE[constraint.relation]
      to_item = subviews_inverse[constraint.secondItem] || "view"
      to_item_attribute = ATTRIBUTE_LOOKUP_INVERSE[constraint.secondAttribute]
      multiplier = constraint.multiplier
      constant = constraint.constant
      priority = PRIORITY_LOOKUP_INVERSE[constraint.priority] || constraint.priority
      "#{constraint.description}\n#{item}.#{item_attribute} #{related_by} #{to_item}.#{to_item_attribute} * #{multiplier} + #{constant} @ #{priority}"
    end

    # transforms a view's NSLayoutConstraints into strings.
    # pass the subviews hash just as you would to Layout#subviews=, followed by the view to
    # describe
    def self.describe_view(subviews, view)
      view.constraints.map do |constraint|
        describe_constraint(subviews, constraint)
      end.join("\n")
    end

    private

    def view_for_item(item)
      if item == "view"
        @view
      elsif item == "topLayoutGuide"
        @block_owner && @block_owner.topLayoutGuide
      elsif item == "bottomLayoutGuide"
        @block_owner && @block_owner.bottomLayoutGuide
      elsif v = (@subviews && @subviews[item])
        v
      end
    end

  end
end
