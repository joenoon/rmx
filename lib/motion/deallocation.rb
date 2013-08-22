module RMExtensions

  module ObjectExtensions

    module Deallocation

      # perform a block before +self+ will dealloc.
      # the block given should have one argument, the object about to be deallocated.
      def rmext_on_dealloc(&block)
        internalObject = ::RMExtensions::OnDeallocInternalObject.create("#{self.class.name}:#{object_id}", self, block)
        @rmext_on_dealloc_blocks ||= {}
        @rmext_on_dealloc_blocks[internalObject] = internalObject
        nil
      end
      
      # removes a previously added block from the deallocation callback list
      def rmext_cancel_on_dealloc(block)
        @rmext_on_dealloc_blocks ||= {}
        if internalObject = @rmext_on_dealloc_blocks[block]
          internalObject.block = nil
          @rmext_on_dealloc_blocks.delete(block)
        end
        nil
      end

    end

  end

  # Used internally by +rmext_on_dealloc+.  The idea is this object is added to the
  # object we want to watch for deallocation.  When the object we want to watch
  # is about to dealloc, this object will dealloc first, so we can execute the block.
  # the object it follows is kept only as a weak reference to not create
  # a retain cycle.
  class OnDeallocInternalObject
    attr_accessor :description, :block
    rmext_weak_attr_accessor :obj
    def self.create(description, obj, block)
      x = new
      x.description = description
      x.obj = obj
      x.block = block
      x
    end
    def dealloc
      # p "dealloc OnDeallocInternalObject #{description}"
      if block
        block.call(obj)
        self.block = nil
      end
      super
    end
  end

end
Object.send(:include, ::RMExtensions::ObjectExtensions::Deallocation)
