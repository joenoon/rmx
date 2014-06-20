module RMExtensions

  module CommonMethods

    def rmext_dealloc
    end

    def dealloc
      if DEBUG_DEALLOC
        p " - dealloc! (queue: #{Dispatch::Queue.current.description})"
      end
      rmext_dealloc
      super
    end

    def inspect
      rmext_object_desc
    end

    def common_deallocs
      NSNotificationCenter.defaultCenter.removeObserver(self)
      objs = []
      ivars = [] + instance_variables
      while ivar = ivars.pop
        if v = instance_variable_get(ivar)
          if !v.is_a?(RMExtensions::WeakHolder) || (v = v.value)
            if v.is_a?(UIView) || v.is_a?(UISearchDisplayController)
              objs.push v
            end
          end
        end
      end
      if is_a?(UIViewController)
        if isViewLoaded
          objs += [ view ]
          objs += view.subviews
        end
      end
      objs.uniq!
      while v = objs.pop
        # p "v", v.inspect
        if v.respond_to?('dataSource=')
          # p "CLEANUP dataSource= on", v.inspect, v.dataSource.inspect
          v.dataSource = nil
        end
        if v.respond_to?('delegate=')
          # p "CLEANUP delegate= on", v.inspect, v.delegate.inspect
          v.delegate = nil
        end
        if v.respond_to?('searchResultsDataSource=')
          # p "CLEANUP searchResultsDataSource= on", v.inspect, v.searchResultsDataSource.inspect
          v.searchResultsDataSource = nil
        end
        if v.respond_to?('searchResultsDelegate=')
          # p "CLEANUP searchResultsDelegate= on", v.inspect, v.searchResultsDelegate.inspect
          v.searchResultsDelegate = nil
        end
      end
      ivars = nil
      objs = nil
      v = nil
    end

    def p(*args)
      if RMExtensions::DEBUG
        _args = args.dup
        _args.unshift rmext_object_desc
        super(*_args)
      end
    end

    def p!(*args)
      _args = args.dup
      _args.push "!"
      p(*_args)
    end

  end

end
